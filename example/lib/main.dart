import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Define the method channel, matching the name used in the native plugin
  static const _platform = MethodChannel('flutter_godot_bridge');

  // Function to call the native method
  Future<void> _launchGodotGame() async {
    try {
      // Call the method, ensuring the name 'launchGodot' matches the Kotlin code
      await _platform.invokeMethod('launchGodot');
    } on PlatformException catch (e) {
      // Handle potential errors, like if the activity is not ready
      print("Failed to launch Godot: ${e.message}");
      // Optionally, show a dialog to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching game: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Dodge The creep Game '),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: _launchGodotGame,
            child: const Text('Start Game'),
          ),
        ),
      ),
    );
  }
}
