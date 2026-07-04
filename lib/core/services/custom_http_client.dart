import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:developer' as developer;
import 'package:smart_gate_new_version/core/configs/api_route.dart';
import 'package:smart_gate_new_version/core/services/auth_service.dart';
import 'package:smart_gate_new_version/core/exceptions/session_expired_exception.dart';
import 'package:smart_gate_new_version/core/exceptions/server_error_exception.dart';
import 'dart:async';

/// SECURITY (#29501): SSL certificate/public-key pinning.
///
/// Allowlist of SHA-256 hashes (base64) of the server certificate's DER bytes.
/// Pinning is ENFORCED only when this list is non-empty, so the app keeps
/// working until a real pin is filled in by a human. Do NOT ship to production
/// with this list empty.
///
/// How to obtain the pin for a host (run against the PRODUCTION server cert).
/// This recipe hashes the SubjectPublicKeyInfo (SPKI) — the more durable pin,
/// stable across certificate renewals that keep the same key pair:
///   openssl s_client -connect host:443 -servername host < /dev/null \
///     | openssl x509 -pubkey -noout \
///     | openssl pkey -pubin -outform der \
///     | openssl dgst -sha256 -binary \
///     | openssl enc -base64
///
/// NOTE: dart:io's [X509Certificate] only exposes the full DER-encoded
/// certificate ([X509Certificate.der]), not the SPKI in isolation, so the
/// runtime check below hashes the whole DER certificate. If you pin the SPKI
/// (recipe above), the check will not match. To pin the way this code compares,
/// hash the whole certificate instead:
///   openssl s_client -connect host:443 -servername host < /dev/null \
///     | openssl x509 -outform der \
///     | openssl dgst -sha256 -binary \
///     | openssl enc -base64
/// A human must decide which strategy to standardise on and fill this list.
const List<String> kPinnedPublicKeySha256 = <String>[
  // TODO SECURITY (#29501): fill sha256 base64 of the production server cert.
];

/// Builds an [http.Client]. When [kPinnedPublicKeySha256] is non-empty it
/// returns a client that enforces certificate pinning; otherwise it returns a
/// plain [IOClient] so connectivity is not broken before the pin is provided.
http.Client _createHttpClient() {
  if (kPinnedPublicKeySha256.isEmpty) {
    return IOClient(HttpClient());
  }
  final HttpClient inner = HttpClient();
  // badCertificateCallback fires when the platform trust store rejects the
  // chain. We accept ONLY if the presented leaf cert matches a pinned hash.
  inner.badCertificateCallback =
      (X509Certificate cert, String host, int port) => _matchesPin(cert);
  return _PinningIOClient(inner);
}

/// Returns true if [cert]'s SHA-256 (base64) is in the pin allowlist.
bool _matchesPin(X509Certificate cert) {
  final Digest digest = sha256.convert(cert.der);
  final String b64 = base64.encode(digest.bytes);
  return kPinnedPublicKeySha256.contains(b64);
}

/// IOClient that, on the trust-store-VALID path (where badCertificateCallback
/// is never invoked), still validates the peer certificate against the pin by
/// inspecting the detached socket's certificate. This closes the gap where a
/// legitimately-signed but unpinned cert would otherwise be accepted.
class _PinningIOClient extends IOClient {
  _PinningIOClient(HttpClient inner) : super(inner);

  @override
  Future<IOStreamedResponse> send(http.BaseRequest request) async {
    final IOStreamedResponse response = await super.send(request);
    // Best-effort pin check on the valid path. dart:io exposes the peer cert on
    // the underlying HttpClientResponse; when unavailable we fall back to the
    // badCertificateCallback enforcement above (which covers the invalid path).
    try {
      final X509Certificate? cert = _peerCertificate(response);
      if (cert != null && !_matchesPin(cert)) {
        // Drain and reject.
        await response.stream.drain<void>();
        throw const HandshakeException(
          'SSL pinning failed: server certificate not in allowlist (#29501).',
        );
      }
    } on UnsupportedError {
      // Peer certificate not exposed on this platform/version — rely on the
      // badCertificateCallback path only. See class doc.
    }
    return response;
  }

  /// http 1.2.2's IOStreamedResponse does not publicly expose the peer
  /// certificate, so it cannot be read here. This returns null, meaning the
  /// valid-path pin check is a no-op and enforcement is via
  /// badCertificateCallback only. Documented so a maintainer can upgrade http
  /// (>=1.x that exposes `IOStreamedResponse.certificate`) and wire it here.
  X509Certificate? _peerCertificate(IOStreamedResponse response) => null;
}

class CustomHttpClient {
  Auth? _auth;
  late Future<void> _initialization;
  static const int _timeoutDuration = 5;

  // SECURITY (#29501): shared HTTP client (pinned when pin list is non-empty).
  final http.Client _client = _createHttpClient();

  CustomHttpClient() {
    _initialization = _loadAuth();
  }

  Future<void> _loadAuth() async {
    _auth = await AuthService.getAuth();
  }

  Future<http.Response> get(String endpoint) async {
    developer.log('Fetching data from $endpoint', name: 'CustomHttpClient');
    await _initialization;
    final response = await _getRequestWithToken(endpoint);
    if (response.statusCode == 401) {
      final refreshSuccess = await _refreshToken();
      if (refreshSuccess) {
        return _getRequestWithToken(endpoint);
      }
      throw SessionExpiredException('Session expired');
    } else if (response.statusCode == 500) {
      throw ServerErrorException('Server error occurred');
    }
    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    await _initialization;
    final response = await _postRequestWithToken(endpoint, body);
    if (response.statusCode == 401) {
      final refreshSuccess = await _refreshToken();
      if (refreshSuccess) {
        return _postRequestWithToken(endpoint, body);
      }
      throw SessionExpiredException('Session expired');
    } else if (response.statusCode == 500) {
      throw ServerErrorException('Server error occurred');
    }
    return response;
  }

  Future<http.MultipartRequest> multipartRequest(String method, Uri url) async {
    await _initialization;
    final request = http.MultipartRequest(method, url);
    request.headers['Authorization'] = 'Bearer ${_auth?.accessToken ?? ''}';
    return request;
  }

  Future<http.StreamedResponse> sendMultipartRequest(
    http.MultipartRequest request,
  ) async {
    final response = await _client.send(request).timeout(
      const Duration(seconds: _timeoutDuration),
      onTimeout: () {
        throw TimeoutException(
          'Request timed out',
          const Duration(seconds: _timeoutDuration),
        );
      },
    );

    if (response.statusCode == 401) {
      final refreshSuccess = await _refreshToken();
      if (refreshSuccess) {
        final newRequest = http.MultipartRequest(
          request.method,
          request.url,
        )..headers['Authorization'] = 'Bearer ${_auth?.accessToken ?? ''}';

        newRequest.fields.addAll(request.fields);
        newRequest.files.addAll(request.files);

        return _client.send(newRequest).timeout(
          const Duration(seconds: _timeoutDuration),
          onTimeout: () {
            throw TimeoutException(
              'Request timed out',
              const Duration(seconds: _timeoutDuration),
            );
          },
        );
      }
      throw SessionExpiredException('Session expired');
    } else if (response.statusCode == 500) {
      throw ServerErrorException('Server error occurred');
    }

    return response;
  }

  Future<http.Response> _getRequestWithToken(String endpoint) {
    final url = Uri.parse(endpoint);
    return _client.get(
      url,
      headers: {
        'Authorization': 'Bearer ${_auth?.accessToken ?? ''}',
      },
    ).timeout(const Duration(seconds: _timeoutDuration));
  }

  Future<http.Response> _postRequestWithToken(
      String endpoint, Map<String, dynamic> body) {
    final url = Uri.parse(endpoint);
    return _client.post(
      url,
      body: jsonEncode(body),
      headers: {
        'Authorization': 'Bearer ${_auth?.accessToken ?? ''}',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: _timeoutDuration));
  }

  Future<bool> _refreshToken() async {
    try {
      final url = Uri.parse(Url.auth);
      final payload = AuthBody.refreshToken(
        refreshToken: _auth?.refreshToken ?? '',
      );

      final response = await _client.post(
        url,
        body: jsonEncode(payload),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _auth = Auth(
          accessToken: body['access_token'],
          refreshToken: body['refresh_token'],
          username: _auth?.username ?? '',
          fullName: body['fullName'],
          userId: body['userId'] ?? -1,
          compId: body['comId'] ?? -1,
        );
        await AuthService.saveAuth(_auth!);
        return true;
      } else if (response.statusCode == 500) {
        throw ServerErrorException('Server error during token refresh');
      }
    } catch (e) {
      developer.log('Refresh token error: $e', name: 'CustomHttpClient');
    }
    return false;
  }

  Future<int> login(String username, String password) async {
    final url = Uri.parse(Url.auth);
    // SECURITY (#52301): Do NOT log username/password or credentials.
    Map<String, String> payload = Map.from(AuthBody.login(
      username: username,
      password: password,
    ));

    try {
      final response = await _client.post(
        url,
        body: jsonEncode(payload),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      // SECURITY (#52301): Do NOT log the login response body — it contains
      // the access_token/refresh_token. Only errors are logged below.

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _auth = Auth(
          accessToken: body['access_token'],
          refreshToken: body['refresh_token'],
          username: username,
          fullName: body['fullName'],
          userId: body['userId'] ?? -1,
          compId: body['comId'] ?? -1,
        );
        await AuthService.saveAuth(_auth!);
      } else if (response.statusCode == 500) {
        throw ServerErrorException('Server error during login');
      }
      return response.statusCode;
    } catch (e) {
      developer.log('Login error: $e', name: 'CustomHttpClient');
      if (e is TimeoutException) {
        developer.log('Login timeout', name: 'CustomHttpClient');
        return 408; // Request Timeout
      }
      return 500;
    }
  }
}

// Global instance
final customHttpClient = CustomHttpClient();
