import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/metric_tile.dart';

class BacktestScreen extends StatelessWidget {
  const BacktestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Strategy Backtesting',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Deep analytical performance breakdown.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              _buildPrimaryMetrics(),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Equity Curve'),
              _buildEquityChart(),
              const SizedBox(height: 32),
              const SectionHeader(title: 'Risk Analysis'),
              _buildRiskGrid(),
              const SizedBox(height: 32),
              const SectionHeader(title: 'Trade History'),
              _buildTradeHistory(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryMetrics() {
    return const Row(
      children: [
        Expanded(
          child: GlassCard(
            height: 100,
            padding: EdgeInsets.all(16),
            child: MetricTile(
              label: 'Total Return',
              value: '+42.8%',
              subValue: 'Annualized',
              isProfit: true,
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: GlassCard(
            height: 100,
            padding: EdgeInsets.all(16),
            child: MetricTile(
              label: 'Win Rate',
              value: '68.5%',
              subValue: '284 Trades',
              valueColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEquityChart() {
    return GlassCard(
      height: 250,
      padding: const EdgeInsets.all(24),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
            getDrawingVerticalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 10),
                FlSpot(1, 10.5),
                FlSpot(2, 10.2),
                FlSpot(3, 11),
                FlSpot(4, 11.5),
                FlSpot(5, 11.2),
                FlSpot(6, 12),
                FlSpot(7, 13),
                FlSpot(8, 12.8),
                FlSpot(9, 14.2),
              ],
              isCurved: true,
              color: AppColors.profit,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.profit.withValues(alpha: 0.2),
                    AppColors.profit.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskGrid() {
    return Column(
      children: [
        Row(
          children: [
            _buildRiskTile('Sharpe Ratio', '1.82', AppColors.primary),
            const SizedBox(width: 16),
            _buildRiskTile('Max Drawdown', '-6.4%', AppColors.loss),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildRiskTile('Profit Factor', '2.4', AppColors.profit),
            const SizedBox(width: 16),
            _buildRiskTile('Volatility', '14.2%', AppColors.warning),
          ],
        ),
      ],
    );
  }

  Widget _buildRiskTile(String label, String value, Color color) {
    return Expanded(
      child: GlassCard(
        height: 80,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeHistory() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final isWin = index % 2 == 0;
        return GlassCard(
          height: 70,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isWin ? 'BTC Long' : 'ETH Short', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${12 - index} March, 2024', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isWin ? '+\$142.50' : '-\$54.20', style: TextStyle(color: isWin ? AppColors.profit : AppColors.loss, fontWeight: FontWeight.bold)),
                  Text(isWin ? 'Win' : 'Loss', style: TextStyle(color: isWin ? AppColors.profit : AppColors.loss, fontSize: 10)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
