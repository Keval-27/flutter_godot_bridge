import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'method_channel_impl.dart';

abstract class FlutterGodotBridgePlatform extends PlatformInterface {
  FlutterGodotBridgePlatform() : super(token: _token);

  static final Object _token = Object();
  static FlutterGodotBridgePlatform _instance =
      MethodChannelFlutterGodotBridge();
  static FlutterGodotBridgePlatform get instance => _instance;

  static set instance(FlutterGodotBridgePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // core Methods
  Future<bool> initializeGodot(Map<String, dynamic> config);
  Future<bool> sendMessage(String channel, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> sendMessageSync(
      String channel, Map<String, dynamic> data);
  Stream<Map<String, dynamic>> getMessageStream(String channel);
  Future<bool> disposeGodot();

  // Performance monitoring
  Future<Map<String, double>> getPerformanceMetrics();
}
