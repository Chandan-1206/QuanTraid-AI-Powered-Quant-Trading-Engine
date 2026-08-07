import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'loading_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedStock = 'RELIANCE.NS';
  String _selectedDuration = '3months';

  final List<String> _stocks = [
    'RELIANCE.NS', 'TCS.NS', 'HDFCBANK.NS', 'INFY.NS', 'ICICIBANK.NS',
    'HINDUNILVR.NS', 'ITC.NS', 'SBIN.NS', 'BHARTIARTL.NS', 'KOTAKBANK.NS'
  ];

  final List<String> _durations = ['1month', '3months', '6months'];
  final Map<String, String> _durationLabels = {
    '1month': '1M',
    '3months': '3M',
    '6months': '6M',
  };

  void _analyzeStock() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoadingScreen(
          stock: _selectedStock,
          duration: _selectedDuration,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Card(
                 child: Padding(
                   padding: const EdgeInsets.all(20),
                   child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         const Text('Market Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 16),
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             _buildMarketInd('NIFTY 50', '+0.8%', true),
                             _buildMarketInd('SENSEX', '+0.7%', true),
                             _buildMarketInd('BANKNIFTY', '-1.2%', false),
                           ]
                         )
                      ]
                   )
                 )
               )
             ),
             Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('AI Stock Analyzer', style: Theme.of(context).textTheme.titleLarge),
             ),
             Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                   color: Theme.of(context).cardTheme.color,
                   borderRadius: BorderRadius.circular(20),
                   border: Theme.of(context).cardTheme.shape is RoundedRectangleBorder
                      ? Border.all(color: (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).side.color)
                      : null,
                ),
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      const Text('Select Target Ticker', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStock,
                            isExpanded: true,
                            dropdownColor: Theme.of(context).cardTheme.color,
                            items: _stocks.map((String stock) {
                              return DropdownMenuItem<String>(
                                value: stock,
                                child: Text(stock),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) setState(() => _selectedStock = newValue);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Analysis Matrix (Duration)', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _durations.map((duration) {
                          bool isSelected = _selectedDuration == duration;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDuration = duration),
                            child: Container(
                              width: 80,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _durationLabels[duration]!,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _analyzeStock,
                          child: const Text('Execute AI Analysis'),
                        ),
                      )
                   ]
                )
             ),
             
             // Top Gainers Mock View for Fintech Feel
             Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('AI Recommended Today', style: Theme.of(context).textTheme.titleLarge),
             ),
             _buildRecommended('TCS.NS', 'BUY', 0.92),
             _buildRecommended('ITC.NS', 'BUY', 0.88),
             
          ],
        )
      )
    );
  }

  Widget _buildMarketInd(String title, String val, bool isPositive) {
      Color c = isPositive ? AppColors.profit : AppColors.loss;
      return Column(
          children: [
             Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
             const SizedBox(height: 4),
             Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(val, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12))
             )
          ]
      );
  }

  Widget _buildRecommended(String stock, String signal, double conf) {
      return Card(
         margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
         elevation: 0,
         child: ListTile(
            leading: CircleAvatar(
               backgroundColor: AppColors.primary.withOpacity(0.2),
               child: const Icon(Icons.analytics, color: AppColors.primary, size: 20),
            ),
            title: Text(stock, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Confidence: ${(conf*100).toStringAsFixed(0)}%'),
            trailing: Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                  color: AppColors.profit.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
               ),
               child: Text(signal, style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.bold)),
            ),
            onTap: () {
               setState(() => _selectedStock = stock);
            }
         ),
      );
  }
}
