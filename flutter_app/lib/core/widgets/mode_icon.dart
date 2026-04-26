import 'package:flutter/material.dart';
import '../models/routing_model.dart';

class ModeIconWidget extends StatelessWidget {
  final TransportMode mode;
  final double size;
  final bool showLabel;

  const ModeIconWidget({
    super.key,
    required this.mode,
    this.size = 36,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: mode.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(size / 3),
            border: Border.all(color: mode.color.withValues(alpha: 0.3)),
          ),
          child: Icon(mode.icon, size: size * 0.5, color: mode.color),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            mode.label,
            style: TextStyle(fontSize: 10, color: mode.color),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Returns transport mode icon for a string mode value
Widget modeIconFromString(String modeValue, {double size = 36, bool showLabel = false}) {
  return ModeIconWidget(
    mode: TransportMode.fromString(modeValue),
    size: size,
    showLabel: showLabel,
  );
}
