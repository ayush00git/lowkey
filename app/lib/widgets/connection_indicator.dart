import 'package:flutter/material.dart';

/// A small animated dot indicating connection status.
class ConnectionIndicator extends StatelessWidget {
  final bool connected;

  const ConnectionIndicator({super.key, required this.connected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: connected ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
            boxShadow: connected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          connected ? 'Connected' : 'Offline',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: connected ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }
}
