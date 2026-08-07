import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SectorStocksScreen extends StatelessWidget {
  final String sector;
  final List stocks;

  const SectorStocksScreen({super.key, required this.sector, required this.stocks});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Top Opportunities: $sector', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: stocks.isEmpty
                ? const Center(child: Text('No stocks available at this time.'))
                : ListView.builder(
                    itemCount: stocks.length,
                    itemBuilder: (context, index) {
                      final stock = stocks[index];
                      return _buildStockCard(stock);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(Map stock) {
    String ticker = stock['stock'] ?? 'UNKNOWN';
    String signal = stock['signal'] ?? 'HOLD';
    double confidence = (stock['confidence'] ?? 0.0) * 100;
    String insight = stock['explanation'] ?? 'No insight available.';
    
    // Determine risk badge (this assumes 'risk' is raw volatility, let's derive LOW/MED/HIGH)
    double riskVal = stock['risk'] ?? 0.0;
    String riskBadge = 'LOW';
    Color riskColor = AppColors.profit;
    if (riskVal > 0.25) {
      riskBadge = 'HIGH';
      riskColor = Colors.red;
    } else if (riskVal > 0.15) {
      riskBadge = 'MEDIUM';
      riskColor = Colors.orange;
    }

    Color signalColor = Colors.grey;
    if (signal.contains('STRONG BUY')) {
      signalColor = Colors.greenAccent.shade700;
    } else if (signal.contains('BUY')) {
      signalColor = AppColors.profit;
    } else if (signal.contains('SELL')) {
      signalColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ticker, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: signalColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: signalColor),
                  ),
                  child: Text(signal, style: TextStyle(color: signalColor, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: riskColor.withOpacity(0.5)),
                  ),
                  child: Text('RISK: $riskBadge', style: TextStyle(color: riskColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Confidence', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('${confidence.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: confidence / 100,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        color: AppColors.primary,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      )
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI Insight', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(height: 4),
                        Text(insight, style: const TextStyle(fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
