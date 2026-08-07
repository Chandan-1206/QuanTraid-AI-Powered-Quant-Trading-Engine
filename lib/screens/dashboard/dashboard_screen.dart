import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/metric_tile.dart';
import '../../widgets/section_header.dart';
import '../../widgets/asset_sparkline.dart';
import '../../data/mock_data.dart';
import '../../models/asset_model.dart';
import '../../widgets/action_button.dart';
import '../market/market_screen.dart';
import '../automated_trading/automated_trading_screen.dart';
import '../strategy_library/strategy_library_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBalanceCard(context),
              const SizedBox(height: 24),
              _buildQuickStats(context),
              const SizedBox(height: 32),
              const SectionHeader(title: 'Market Sentiment'),
              _buildSentimentCard(context),
              const SizedBox(height: 32),
              SectionHeader(
                title: 'Watchlist',
                actionLabel: 'See All Markets',
                onActionPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MarketScreen()));
                },
              ),
              _buildWatchlist(context),
              const SizedBox(height: 32),
              const SectionHeader(title: 'AI Insight of the Day'),
              _buildAIInsight(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Trader',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const Text(
              'Dashboard Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=quantraid'),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final portfolio = MockData.portfolio;
    return GlassCard(
      height: 220,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Portfolio Balance',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.profit.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: AppColors.profit, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '+${portfolio.dailyPnLPercent}%',
                      style: const TextStyle(color: AppColors.profit, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${portfolio.totalBalance.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 36),
          ),
          const Spacer(),
          SizedBox(
            height: 60,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 4),
                      FlSpot(2, 3.5),
                      FlSpot(3, 5),
                      FlSpot(4, 4.5),
                      FlSpot(5, 6),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: GlassCard(
            height: 100,
            padding: EdgeInsets.all(16),
            child: MetricTile(
              label: 'Daily P/L',
              value: '+\$3,452',
              subValue: '+2.84%',
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassCard(
            height: 100,
            padding: const EdgeInsets.all(16),
            child: MetricTile(
              label: 'AI Confidence',
              value: '87%',
              subValue: 'High Signal',
              valueColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSentimentCard(BuildContext context) {
    return GlassCard(
      height: 120,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bullish Sentiment',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'The AI models show high accumulation in tech sectors.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          CircularProgressIndicator(
            value: 0.72,
            backgroundColor: AppColors.surfaceLight,
            color: AppColors.profit,
            strokeWidth: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlist(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: MockData.assets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final asset = MockData.assets[index];
        final isProfit = asset.changePercent >= 0;
        return GlassCard(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    asset.symbol[0],
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(asset.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(asset.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              AssetSparkline(data: asset.sparkline, isPositive: isProfit),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('\$${asset.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${isProfit ? '+' : ''}${asset.changePercent}%',
                    style: TextStyle(color: isProfit ? AppColors.profit : AppColors.loss, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAIInsight(BuildContext context) {
    return GlassCard(
      height: 200,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Text(
                'Trading Tip',
                style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tesla (TSLA) is showing a massive divergence in AI RSI models. Potential breakout expected within 48 hours.',
            style: TextStyle(color: AppColors.textPrimary, height: 1.5),
          ),
          const Spacer(),
          ActionButton(
            label: 'Manage Bots',
            icon: Icons.smart_toy_outlined,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AutomatedTradingScreen()));
            },
          ),
        ],
      ),
    );
  }
}
