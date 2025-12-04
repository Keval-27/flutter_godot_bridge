// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'flutter_godot_bridge_platform_interface.dart';

/// A web implementation of the FlutterGodotBridgePlatform of the FlutterGodotBridge plugin.
class FlutterGodotBridgeWeb extends FlutterGodotBridgePlatform {
  /// Constructs a FlutterGodotBridgeWeb
  FlutterGodotBridgeWeb();

  static void registerWith(Registrar registrar) {
    FlutterGodotBridgePlatform.instance = FlutterGodotBridgeWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }
}
