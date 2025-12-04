import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_godot_bridge_platform_interface.dart';

/// An implementation of [FlutterGodotBridgePlatform] that uses method channels.
class MethodChannelFlutterGodotBridge extends FlutterGodotBridgePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_godot_bridge');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
