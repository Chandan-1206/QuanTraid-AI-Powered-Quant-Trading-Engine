import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AssetSparkline extends StatelessWidget {
  final List<double> data;
  final bool isPositive;

  const AssetSparkline({
    super.key,
    required this.data,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 80,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: data.reduce((a, b) => a < b ? a : b) * 0.99,
          maxY: data.reduce((a, b) => a > b ? a : b) * 1.01,
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              color: isPositive ? AppColors.profit : AppColors.loss,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isPositive ? AppColors.profit : AppColors.loss).withValues(alpha: 0.2),
                    (isPositive ? AppColors.profit : AppColors.loss).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
