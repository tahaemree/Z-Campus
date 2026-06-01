import 'dart:ui';

import 'package:flutter/material.dart';

class OverImageIconButton extends StatelessWidget {
  const OverImageIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.iconColor = Colors.white,
    this.backgroundColor,
    this.margin = EdgeInsets.zero,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color iconColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final effectiveBackground =
        backgroundColor ?? Colors.black.withValues(alpha: 0.26);

    return Padding(
      padding: margin,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DecoratedBox(
              decoration: BoxDecoration(
                color: effectiveBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            child: IconButton(
              tooltip: tooltip,
              icon: Icon(icon, color: iconColor, size: 24),
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}
