import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_godot_bridge_method_channel.dart';

abstract class FlutterGodotBridgePlatform extends PlatformInterface {
  /// Constructs a FlutterGodotBridgePlatform.
  FlutterGodotBridgePlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterGodotBridgePlatform _instance = MethodChannelFlutterGodotBridge();

  /// The default instance of [FlutterGodotBridgePlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterGodotBridge].
  static FlutterGodotBridgePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterGodotBridgePlatform] when
  /// they register themselves.
  static set instance(FlutterGodotBridgePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
