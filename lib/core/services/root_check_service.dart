import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RootCheckService {
  const RootCheckService(this._channel);

  final MethodChannel _channel;

  Future<bool> isDeviceRooted() async {
    try {
      final bool? isRooted = await _channel.invokeMethod<bool>('isRooted');
      return isRooted ?? false;
    } on PlatformException catch (error) {
      debugPrint('Root detection failed: $error');
      return false;
    }
  }
}

const rootCheckService = RootCheckService(MethodChannel('root_check'));
