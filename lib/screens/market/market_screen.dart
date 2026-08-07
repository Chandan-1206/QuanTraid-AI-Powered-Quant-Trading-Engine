import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

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
                'Market Analytics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Global market insights and trending assets.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              _buildMarketIndices(),
              const SizedBox(height: 32),
              const SectionHeader(title: 'Top Gainers'),
              _buildAssetGrid(true),
              const SizedBox(height: 32),
              const SectionHeader(title: 'Top Losers'),
              _buildAssetGrid(false),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketIndices() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildIndexCard('S&P 500', '5,123.42', '+1.2%'),
          const SizedBox(width: 16),
          _buildIndexCard('NASDAQ', '16,274.90', '+1.5%'),
          const SizedBox(width: 16),
          _buildIndexCard('NIFTY 50', '22,450.10', '-0.3%'),
        ],
      ),
    );
  }

  Widget _buildIndexCard(String name, String value, String change) {
    final isProfit = change.contains('+');
    return GlassCard(
      width: 160,
      height: 100,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(color: isProfit ? AppColors.profit : AppColors.loss, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetGrid(bool isPositive) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return GlassCard(
          height: 100, // Explicit height for grid items
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isPositive ? ['NVDA', 'AMD', 'META', 'MSFT'][index] : ['TSLA', 'AAPL', 'GOOGL', 'AMZN'][index], style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$${(150 + index * 10).toString()}', style: const TextStyle(fontSize: 12)),
                  Text(
                    '${isPositive ? '+' : '-'}${2 + index}.5%',
                    style: TextStyle(color: isPositive ? AppColors.profit : AppColors.loss, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
