import 'dart:ffi' as ffi;
import 'dart:io';

// Native function signatures
typedef InitializeSharedMemoryNative = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint8> buffer,
  ffi.Size size,
);

typedef InitializeSharedMemoryDart = int Function(
  ffi.Pointer<ffi.Uint8> buffer,
  int size,
);

typedef SendBinaryMessageNative = ffi.Int32 Function(ffi.Size length);
typedef SendBinaryMessageDart = int Function(int length);

typedef ReceiveBinaryMessageNative = ffi.Int32 Function();
typedef ReceiveBinaryMessageDart = int Function();

typedef CleanupNative = ffi.Void Function();
typedef CleanupDart = void Function();

// Performance metrics struct
final class PerformanceMetricsStruct extends ffi.Struct {
  @ffi.Uint64()
  external int messagesSent;

  @ffi.Uint64()
  external int messagesReceived;

  @ffi.Uint64()
  external int totalLatencyNanos;

  @ffi.Uint64()
  external int minLatencyNanos;

  @ffi.Uint64()
  external int maxLatencyNanos;
}

typedef GetPerformanceMetricsNative = ffi.Pointer<PerformanceMetricsStruct>
    Function();
typedef GetPerformanceMetricsDart = ffi.Pointer<PerformanceMetricsStruct>
    Function();

class NativeBindings {
  late final ffi.DynamicLibrary _dylib;
  late final InitializeSharedMemoryDart initializeSharedMemory;
  late final SendBinaryMessageDart sendBinaryMessage;
  late final ReceiveBinaryMessageDart receiveBinaryMessage;
  late final GetPerformanceMetricsDart getPerformanceMetrics;
  late final CleanupDart cleanup;

  NativeBindings(ffi.DynamicLibrary dylib) : _dylib = dylib {
    try {
      initializeSharedMemory = _dylib
          .lookup<ffi.NativeFunction<InitializeSharedMemoryNative>>(
              'initialize_shared_memory')
          .asFunction();

      sendBinaryMessage = _dylib
          .lookup<ffi.NativeFunction<SendBinaryMessageNative>>(
              'send_binary_message')
          .asFunction();

      receiveBinaryMessage = _dylib
          .lookup<ffi.NativeFunction<ReceiveBinaryMessageNative>>(
              'receive_binary_message')
          .asFunction();

      getPerformanceMetrics = _dylib
          .lookup<ffi.NativeFunction<GetPerformanceMetricsNative>>(
              'get_performance_metrics')
          .asFunction();

      cleanup = _dylib
          .lookup<ffi.NativeFunction<CleanupNative>>('cleanup')
          .asFunction();
    } catch (e) {
      throw Exception('Failed to load native bindings: $e');
    }
  }

  static ffi.DynamicLibrary _openLibrary() {
    if (Platform.isAndroid) {
      return ffi.DynamicLibrary.open('libgodot_bridge.so');
    } else if (Platform.isIOS) {
      return ffi.DynamicLibrary.process();
    } else if (Platform.isMacOS) {
      return ffi.DynamicLibrary.open('libgodot_bridge.dylib');
    } else if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('godot_bridge.dll');
    } else if (Platform.isLinux) {
      return ffi.DynamicLibrary.open('libgodot_bridge.so');
    }
    throw UnsupportedError(
        'Platform ${Platform.operatingSystem} is not supported');
  }

  factory NativeBindings.create() {
    final dylib = _openLibrary();
    return NativeBindings(dylib);
  }

  void dispose() {
    cleanup();
  }
}
