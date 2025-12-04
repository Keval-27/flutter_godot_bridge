import 'package:flutter/material.dart';
import 'godot_widget.dart';

class GodotOverlay extends StatefulWidget {
  final GodotWidget godotWidget;
  final List<Widget> overlayWidgets;
  final AlignmentGeometry overlayAlignment;
  final EdgeInsetsGeometry overlayPadding;
  final bool allowInteraction;

  const GodotOverlay({
    super.key,
    required this.godotWidget,
    this.overlayWidgets = const [],
    this.overlayAlignment = Alignment.topRight,
    this.overlayPadding = const EdgeInsets.all(16.0),
    this.allowInteraction = true,
  });

  @override
  State<GodotOverlay> createState() => _GodotOverlayState();
}

class _GodotOverlayState extends State<GodotOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Godot game view
        widget.godotWidget,

        // Flutter UI overlays
        if (widget.overlayWidgets.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !widget.allowInteraction,
              child: Align(
                alignment: widget.overlayAlignment,
                child: Padding(
                  padding: widget.overlayPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.overlayWidgets,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
