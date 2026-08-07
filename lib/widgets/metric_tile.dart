import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData? icon;
  final Color? valueColor;
  final bool isProfit;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.subValue,
    this.icon,
    this.valueColor,
    this.isProfit = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subValue != null)
          Text(
            subValue!,
            style: TextStyle(
              color: isProfit ? AppColors.profit : AppColors.loss,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
