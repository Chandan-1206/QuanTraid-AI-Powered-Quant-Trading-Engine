import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData? icon;

  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isPrimary ? BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppColors.primaryGradient, // Soft gradient for buttons
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2), // Subtler shadow
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ) : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.transparent : AppColors.surfaceLight, // Transparent so gradient shows
          shadowColor: Colors.transparent, // Let Container handle shadow
          foregroundColor: Colors.white, // White text for primary
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary ? BorderSide.none : BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}
