import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_godot_bridge/flutter_godot_bridge.dart';
import 'package:flutter_godot_bridge/flutter_godot_bridge_platform_interface.dart';
import 'package:flutter_godot_bridge/flutter_godot_bridge_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterGodotBridgePlatform
    with MockPlatformInterfaceMixin
    implements FlutterGodotBridgePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterGodotBridgePlatform initialPlatform = FlutterGodotBridgePlatform.instance;

  test('$MethodChannelFlutterGodotBridge is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterGodotBridge>());
  });

  test('getPlatformVersion', () async {
    FlutterGodotBridge flutterGodotBridgePlugin = FlutterGodotBridge();
    MockFlutterGodotBridgePlatform fakePlatform = MockFlutterGodotBridgePlatform();
    FlutterGodotBridgePlatform.instance = fakePlatform;

    expect(await flutterGodotBridgePlugin.getPlatformVersion(), '42');
  });
}
