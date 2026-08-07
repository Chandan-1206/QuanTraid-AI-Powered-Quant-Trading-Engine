import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'portfolio_input_screen.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Advisor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.analytics_outlined, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              'Advanced Portfolio Optimization',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Analyze portfolio health, optimize allocation, and get AI-driven diversification suggestions.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PortfolioInputScreen(mode: 'new_investment')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('New Investment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PortfolioInputScreen(mode: 'optimize_existing')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Optimize Existing Portfolio', style: TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Coming Soon'),
                    content: const Text('Screenshot upload feature is coming soon.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Upload Screenshot of Portfolio'),
            )
          ],
        ),
      ),
    );
  }
}
