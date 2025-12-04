import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GodotWidget extends StatefulWidget {
  final String? projectPath;
  final String mainScene;
  final Map<String, dynamic>? initialConfig;
  final Function(String channel, Map<String, dynamic> message)? onMessage;
  final Function(Map<String, dynamic> metrics)? onPerformanceUpdate;

  const GodotWidget({
    Key? key,
    this.projectPath,
    required this.mainScene,
    this.initialConfig,
    this.onMessage,
    this.onPerformanceUpdate,
  }) : super(key: key);

  @override
  State<GodotWidget> createState() => _GodotWidgetState();
}

class _GodotWidgetState extends State<GodotWidget> {
  static const MethodChannel _channel = MethodChannel('flutter_godot_bridge');
  bool _isInitialized = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeGodot();
  }

  Future<void> _initializeGodot() async {
    try {
      final result = await _channel.invokeMethod('initializeGodot', {
        'projectPath': widget.projectPath ?? '',
        'mainScene': widget.mainScene,
        'config': widget.initialConfig ?? {},
      });

      setState(() {
        _isInitialized = true;
      });

      debugPrint('Godot initialized: $result');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      debugPrint('Error initializing Godot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return const AndroidView(
      viewType: 'flutter_godot_bridge_view',
      layoutDirection: TextDirection.ltr,
      creationParamsCodec: StandardMessageCodec(),
    );
  }

  @override
  void dispose() {
    _channel.invokeMethod('disposeGodot');
    super.dispose();
  }
}
