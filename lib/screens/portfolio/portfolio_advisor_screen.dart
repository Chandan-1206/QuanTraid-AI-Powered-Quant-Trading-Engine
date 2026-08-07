import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../data/api_service.dart';
import 'sector_stocks_screen.dart';

class PortfolioAdvisorScreen extends StatefulWidget {
  final String mode;
  final List<Map<String, dynamic>> portfolio;
  final double budget;

  const PortfolioAdvisorScreen({
    super.key,
    required this.mode,
    required this.portfolio,
    required this.budget,
  });

  @override
  State<PortfolioAdvisorScreen> createState() => _PortfolioAdvisorScreenState();
}

class _PortfolioAdvisorScreenState extends State<PortfolioAdvisorScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnalysis();
  }

  Future<void> _fetchAnalysis() async {
    try {
      final res = await ApiService().analyzePortfolio(widget.mode, widget.portfolio, widget.budget);
      setState(() {
        _result = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analyzing Portfolio...'), backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null || _result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error'), backgroundColor: Colors.transparent, elevation: 0),
        body: Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red))),
      );
    }

    final status = _result!['portfolio_status'] ?? 'UNKNOWN';
    final riskLevel = _result!['risk_level'] ?? 'UNKNOWN';
    final ret = ((_result!['portfolio_return'] as num?)?.toDouble() ?? 0.0) * 100;
    final risk = ((_result!['portfolio_risk'] as num?)?.toDouble() ?? 0.0) * 100;
    final sharpe = (_result!['sharpe_ratio'] as num?)?.toDouble() ?? 0.0;
    final weights = _result!['optimized_weights'] as List? ?? [];
    final sectors = _result!['suggested_sectors'] as List? ?? [];
    final rankedStocks = _result!['ranked_stocks'] as Map<String, dynamic>? ?? {};
    final btMetrics = _result!['backtest_metrics'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status and Metrics
            _buildStatusHeader(status),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMetricCard('Expected Return', '${ret.toStringAsFixed(2)}%', AppColors.profit)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard('Risk (Volatility)', '${risk.toStringAsFixed(2)}%', _getRiskColor(riskLevel))),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard('Sharpe Ratio', sharpe.toStringAsFixed(2), AppColors.primary)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Allocation Chart
            const Text('Optimized Allocation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildPieChart(weights),
            ),
            const SizedBox(height: 24),

            // Backtesting Metrics
            const Text('Backtesting Engine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Model Accuracy', style: TextStyle(color: Colors.grey)),
                        Text('${((btMetrics['direction_accuracy'] ?? 0) * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Reliability', style: TextStyle(color: Colors.grey)),
                        Text('${btMetrics['model_reliability'] ?? 'N/A'}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _getReliabilityColor(btMetrics['model_reliability']))),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Suggestions
            const Text('Diversification Suggestions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildSuggestionsText(status, sectors),
            const SizedBox(height: 16),
            
            // Sector Buttons
            if (sectors.isNotEmpty) ...[
              const Text('Explore Opportunities', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sectors.map((sector) {
                  return ActionChip(
                    label: Text(sector.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    side: const BorderSide(color: AppColors.primary),
                    onPressed: () {
                      _showSectorStocks(context, sector.toString(), rankedStocks[sector.toString()] ?? []);
                    },
                  );
                }).toList(),
              )
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Portfolio Optimization applied.')));
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Optimize Portfolio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(String status) {
    Color bg;
    String text;
    IconData icon;
    if (status == 'OVER_CONCENTRATED') {
      bg = Colors.red;
      text = 'Warning: Over-Concentrated';
      icon = Icons.warning;
    } else if (status == 'UNDER_DIVERSIFIED') {
      bg = Colors.orange;
      text = 'Warning: Under-Diversified';
      icon = Icons.info;
    } else {
      bg = AppColors.profit;
      text = 'Status: Balanced';
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg),
      ),
      child: Row(
        children: [
          Icon(icon, color: bg),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(val, style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPieChart(List weights) {
    if (weights.isEmpty) return const Center(child: Text('No allocation data'));
    
    // Filter out zero or near-zero weights to prevent fl_chart native rendering crashes
    final validWeights = weights.where((w) => ((w['weight'] as num?)?.toDouble() ?? 0.0) > 0.001).toList();

    if (validWeights.isEmpty) {
      return const Center(child: Text('Unable to render allocation (all weights are effectively zero)'));
    }
    
    final List<Color> colors = [AppColors.primary, AppColors.profit, AppColors.secondary, Colors.orange, Colors.purple, Colors.teal];
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: validWeights.asMap().entries.map((e) {
          int i = e.key;
          Map w = e.value;
          double value = ((w['weight'] as num?)?.toDouble() ?? 0.0) * 100;
          
          return PieChartSectionData(
            color: colors[i % colors.length],
            value: value,
            title: value > 0.1 ? '${w['stock']}\n${value.toStringAsFixed(1)}%' : '',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSuggestionsText(String status, List sectors) {
    String message = '';
    if (status == 'OVER_CONCENTRATED') {
      message = 'Your portfolio is heavily skewed towards one or two stocks. Consider reducing exposure to your top holdings by 10-15% and reallocating to other sectors.';
    } else if (status == 'UNDER_DIVERSIFIED') {
      message = 'Your portfolio lacks broader market coverage. Expanding into different sectors can reduce overall risk.';
    } else {
      message = 'Your portfolio is well diversified. Consider the optimized weights to maximize your Sharpe Ratio.';
    }

    if (sectors.isNotEmpty) {
      message += '\n\nWe recommend exploring stocks in: ${sectors.join(", ")}.';
    }

    return Text(message, style: const TextStyle(fontSize: 14, height: 1.5));
  }

  Color _getRiskColor(String riskLevel) {
    if (riskLevel == 'HIGH') return Colors.red;
    if (riskLevel == 'MEDIUM') return Colors.orange;
    return Colors.green;
  }
  
  Color _getReliabilityColor(dynamic rel) {
    if (rel == 'GOOD' || rel == 'EXCELLENT') return AppColors.profit;
    if (rel == 'POOR') return Colors.red;
    return Colors.orange;
  }

  void _showSectorStocks(BuildContext context, String sector, List stocks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SectorStocksScreen(sector: sector, stocks: stocks),
    );
  }
}
