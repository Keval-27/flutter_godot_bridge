import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'platform_interface.dart';

class MethodChannelFlutterGodotBridge extends FlutterGodotBridgePlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_godot_bridge');
  final Map<String, StreamController<Map<String, dynamic>>> _messageStreams =
      {};

// For Initializing Godot
  @override
  Future<bool> initializeGodot(Map<String, dynamic> config) async {
    try {
      final result =
          await methodChannel.invokeMethod<bool>('initializeGodot', config);

      // Setup message listener
      methodChannel.setMethodCallHandler(_handleMethodCall);
      return result ?? false;
    } catch (e) {
      debugPrint('Error initializing Godot : $e ');
      return false;
    }
  }

  // For Sending Message to native
  @override
  Future<bool> sendMessage(String channel, Map<String, dynamic> data) async {
    try {
      final result = await methodChannel.invokeMethod('sendMessage', {
        'channel': channel,
        'data': data,
        'timestamp': DateTime.now().microsecondsSinceEpoch,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error Sending Message : $e');
      return false;
    }
  }

  // Requests an immediate response from native (Request - Response)
  @override
  Future<Map<String, dynamic>?> sendMessageSync(
      String channel, Map<String, dynamic> data) async {
    try {
      final result = await methodChannel
          .invokeMethod<Map<String, dynamic>>('sendMessageSync', {
        'channel': channel,
        'data': data,
        'timestamp': DateTime.now().microsecondsSinceEpoch,
      });
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      debugPrint('Error Sending Sync Message : $e');
      return null;
    }
  }

  // Returns a Broadcast stream for the requested channel
  @override
  Stream<Map<String, dynamic>> getMessageStream(String channel) {
    if (!_messageStreams.containsKey(channel)) {
      _messageStreams[channel] =
          StreamController<Map<String, dynamic>>.broadcast();
    }
    return _messageStreams[channel]!.stream;
  }

  // Dart-side entry point for messages invoked from native
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onGodotMessage':
        final String channel = call.arguments['channel'];
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(call.arguments['data']);

        if (_messageStreams.containsKey(channel)) {
          _messageStreams[channel]!.add(data);
        }
        break;
      default:
        debugPrint('Unknown method call : ${call.method}');
    }
  }

  //Closes all stream controllers, clears the map, then tells native to dispose the Godot instance.
  @override
  Future<bool> disposeGodot() async {
    try {
      // close all streams
      for (final controller in _messageStreams.values) {
        await controller.close();
      }
      _messageStreams.clear();
      final result = await methodChannel.invokeMethod<bool>('disposeGodot');
      return result ?? false;
    } catch (e) {
      debugPrint('Error disposing Godot : $e');
      return false;
    }
  }

  // native side for metrics (e.g., FPS, memory, CPU).
  @override
  Future<Map<String, double>> getPerformanceMetrics() async {
    try {
      final result = await methodChannel
          .invokeMethod<Map<String, dynamic>>('getPeformanceMetrics');
      return Map<String, double>.from(result ?? {});
    } catch (e) {
      debugPrint('error Getting Performance $e');
      return {};
    }
  }
}
