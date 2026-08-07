import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/action_button.dart';
import '../../data/mock_data.dart';
import '../../models/strategy_model.dart';
import '../strategy_library/strategy_library_screen.dart';

class StrategyGeneratorScreen extends StatefulWidget {
  const StrategyGeneratorScreen({super.key});

  @override
  State<StrategyGeneratorScreen> createState() => _StrategyGeneratorScreenState();
}

class _StrategyGeneratorScreenState extends State<StrategyGeneratorScreen> {
  bool _isGenerating = false;
  RiskProfile _selectedRisk = RiskProfile.medium;

  void _generate() {
    setState(() => _isGenerating = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isGenerating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI Strategy Generator',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.collections_bookmark_outlined, color: AppColors.primary),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => StrategyLibraryScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Create custom trading models with machine learning.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              _buildSelectionArea(),
              const SizedBox(height: 32),
              Center(
                child: ActionButton(
                  label: _isGenerating ? 'AI is Thinking...' : 'Generate New Strategy',
                  icon: _isGenerating ? Icons.hourglass_empty : Icons.auto_awesome,
                  onPressed: _isGenerating ? () {} : _generate,
                ),
              ),
              const SizedBox(height: 40),
              if (_isGenerating) _buildGeneratingState() else _buildResultsArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionArea() {
    return GlassCard(
      height: 250,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Risk Appetite', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: RiskProfile.values.map((risk) {
              final isSelected = _selectedRisk == risk;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedRisk = risk),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
                    ),
                    child: Center(
                      child: Text(
                        risk.name.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Asset Class', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Crypto', 'Stocks', 'Forex', 'Indices'].map((t) => Chip(
              label: Text(t),
              backgroundColor: AppColors.surfaceLight,
              side: BorderSide.none,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            'Analyzing market correlations...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            'Running $randVal backtests across 500+ assets.',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  int get randVal => 42 + (DateTime.now().second % 100);

  Widget _buildResultsArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Available AI Strategies'),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: MockData.strategies.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final strategy = MockData.strategies[index];
            return GlassCard(
              height: 220,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(strategy.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(strategy.confidenceScore * 100).toInt()}% Conf.',
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(strategy.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetric('Win Rate', '${(strategy.winRate * 100).toInt()}%'),
                      _buildMetric('Exp. Return', '+${strategy.expectedReturn}%'),
                      _buildMetric('Risk Score', strategy.riskScore.toString()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ActionButton(
                      label: 'Deploy Strategy',
                      onPressed: () {},
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
