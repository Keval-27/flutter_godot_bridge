import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import '../native_bindings.dart';

class HighPerformanceMessageChannel {
  static const int _maxMessageSize = 8192;

  late final ffi.Pointer<ffi.Uint8> _sharedBuffer;
  late final NativeBindings _bindings;
  final Completer<void> _initCompleter = Completer<void>();

  // Performance metrics
  int _messagesSent = 0;
  int _messageReceived = 0;
  final List<int> _latencies = [];

  Future<void> initialize() async {
    try {
      _bindings = NativeBindings(ffi.DynamicLibrary.open('libgodot_bridge.so'));
      _sharedBuffer = calloc<ffi.Uint8>(_maxMessageSize);

      final result =
          _bindings.initializeSharedMemory(_sharedBuffer, _maxMessageSize);
      if (result == 0) {
        throw Exception('Failed to initialize shared memory');
      }
      _initCompleter.complete();
    } catch (e) {
      _initCompleter.completeError(e);
    }
  }

  Future<bool> sendBinaryMessage(Uint8List data) async {
    await _initCompleter.future;

    if (data.length > _maxMessageSize) {
      throw ArgumentError(
          'Message too large : ${data.length} > $_maxMessageSize');
    }
    final startTime = DateTime.now().microsecondsSinceEpoch;

    // Copy data to shared Buffer
    for (int i = 0; i < data.length; i++) {
      _sharedBuffer[i] = data[i];
    }

    final result = _bindings.sendBinaryMessage(data.length);
    if (result == 1) {
      _messagesSent++;
      final latency = DateTime.now().microsecondsSinceEpoch - startTime;
      _latencies.add(latency);
    }

    // Keep only last 100 latency measurements
    if (_latencies.length > 100) {
      _latencies.removeAt(0);
    }
    return result == 1;
  }

  Future<Uint8List?> receiveBinaryMessage() async {
    await _initCompleter.future;

    final length = _bindings.receiveBinaryMessage();
    if (length <= 0) return null;

    final data = Uint8List(length);
    for (int i = 0; i < length; i++) {
      data[i] = _sharedBuffer[i];
    }

    _messageReceived++;
    return data;
  }

  Map<String, double> getPerformanceMetrics() {
    if (_latencies.isEmpty) return {};

    final avgLatency = _latencies.reduce((a, b) => a + b) / _latencies.length;
    final minLatency = _latencies.reduce((a, b) => a < b ? a : b);
    final maxLatency = _latencies.reduce((a, b) => a > b ? a : b);

    return {
      'averageLatencyMicros': avgLatency,
      'minLatencyMicros': minLatency.toDouble(),
      'maxLatencyMicros': maxLatency.toDouble(),
      'messagesSent': _messagesSent.toDouble(),
      'messagesReceived': _messageReceived.toDouble(),
    };
  }

  void dispose() {
    calloc.free(_sharedBuffer);
    _bindings.cleanup();
  }
}
