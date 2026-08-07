import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding; // Changed to be nullable

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 16, // Fintech 16px+
    this.blur = 10,
    this.padding, // Removed default value, now nullable
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      borderRadius: borderRadius,
      blur: blur,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF161D26).withValues(alpha: 0.95),
          const Color(0xFF161D26).withValues(alpha: 0.85),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1F2937),
          const Color(0xFF1F2937).withValues(alpha: 0.5),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
