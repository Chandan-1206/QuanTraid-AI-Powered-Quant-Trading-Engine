import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import '../../data/mock_data.dart';

class StrategyLibraryScreen extends StatelessWidget {
  const StrategyLibraryScreen({super.key});

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
                'Strategy Library',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Access your saved and AI-optimized models.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              const SectionHeader(title: 'Top AI Collections'),
              _buildHorizontalLibrary(),
              const SizedBox(height: 32),
              const SectionHeader(title: 'My Favorites'),
              _buildVerticalList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalLibrary() {
    final categories = ['Neural Networks', 'Mean Reversion', 'Arbitrage', 'Momentum'];
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return GlassCard(
            width: 140,
            height: 120,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_copy_outlined, color: AppColors.primary, size: 24),
                const SizedBox(height: 12),
                Text(
                  categories[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: MockData.strategies.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final strategy = MockData.strategies[index];
        return GlassCard(
          height: 70,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.surfaceLight, shape: BoxShape.circle),
                child: const Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(strategy.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('ROI: +${strategy.expectedReturn}% | Win: ${(strategy.winRate * 100).toInt()}%',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 14),
            ],
          ),
        );
      },
    );
  }
}
