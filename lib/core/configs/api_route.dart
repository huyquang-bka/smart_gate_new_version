class ApiRoute {
  // Base URLs
  static const String baseUrl = "https://crd.atin.vn";
  static const String aiServiceUrl = "http://atin.bkaitech.com:6299";
}

// URI Paths
class UriPath {
  // GET endpoints
  static const String getCheckPoint =
      "/Service/api/checkPoint?page=1&itemsPerPage=999";

  // POST endpoints
  static const String postSeal = "/api/v1/recognize/seal";

  // Auth endpoint
  static const String auth = "/Service/api/token/auth";
}

// Auth Bodies
class AuthBody {
  static Map<String, String> login({
    required String username,
    required String password,
  }) =>
      {
        "grant_type": "password",
        "client_id": "EPS",
        "client_secret": "b0udcdl8k80cqiyt63uq",
        "username": username,
        "password": password,
      };

  static Map<String, String> refreshToken({
    required String refreshToken,
  }) =>
      {
        "grant_type": "refresh_token",
        "client_id": "EPS",
        "client_secret": "b0udcdl8k80cqiyt63uq",
        "refresh_token": refreshToken,
      };
}

// Full URLs
class Url {
  // Auth
  static const String auth = "${ApiRoute.baseUrl}${UriPath.auth}";

  // GET endpoints

  static const String getCheckPoint =
      "${ApiRoute.baseUrl}${UriPath.getCheckPoint}";

  // POST endpoints
  static const String postSeal = "${ApiRoute.aiServiceUrl}${UriPath.postSeal}";

  // File Service
  static const String fileService = "${ApiRoute.baseUrl}/Service/files";

  // Version Checker
  static const String versionChecker =
      "https://api.github.com/repos/YOUR_USERNAME/YOUR_REPO/releases/latest";
}