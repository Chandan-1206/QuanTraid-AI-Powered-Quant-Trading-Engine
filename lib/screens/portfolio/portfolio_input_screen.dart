import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'portfolio_advisor_screen.dart';

class PortfolioInputScreen extends StatefulWidget {
  final String mode;
  const PortfolioInputScreen({super.key, required this.mode});

  @override
  State<PortfolioInputScreen> createState() => _PortfolioInputScreenState();
}

class _PortfolioInputScreenState extends State<PortfolioInputScreen> {
  final List<Map<String, dynamic>> _portfolio = [];
  final TextEditingController _stockCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _budgetCtrl = TextEditingController(text: "0");

  @override
  void dispose() {
    _stockCtrl.dispose();
    _amountCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _addStock() {
    if (_stockCtrl.text.isNotEmpty && _amountCtrl.text.isNotEmpty) {
      final stock = _stockCtrl.text.trim().toUpperCase();
      final normalizedStock = stock.endsWith('.NS')
          ? stock.substring(0, stock.length - 3)
          : stock;
      setState(() {
        _portfolio.add({
          "stock": normalizedStock,
          "amount": double.tryParse(_amountCtrl.text) ?? 0.0,
        });
        _stockCtrl.clear();
        _amountCtrl.clear();
      });
    }
  }

  void _removeStock(int index) {
    setState(() {
      _portfolio.removeAt(index);
    });
  }

  void _analyze() {
    if (_portfolio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one stock.')),
      );
      return;
    }
    double budget = double.tryParse(_budgetCtrl.text) ?? 0.0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PortfolioAdvisorScreen(
          mode: widget.mode,
          portfolio: _portfolio,
          budget: budget,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isOptimize = widget.mode == 'optimize_existing';

    return Scaffold(
      appBar: AppBar(
        title: Text(isOptimize ? 'Your Portfolio' : 'New Investment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isOptimize) ...[
              TextField(
                controller: _budgetCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Additional Budget (Optional)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _stockCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Stock Ticker (e.g. TCS)',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Amount (₹)',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      onPressed: _addStock,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Added Stocks',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _portfolio.isEmpty
                  ? const Center(
                      child: Text(
                        'No stocks added yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _portfolio.length,
                      itemBuilder: (context, index) {
                        final item = _portfolio[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                Icons.show_chart,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              item['stock'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('₹ ${item['amount']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeStock(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            ElevatedButton(
              onPressed: _analyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Analyze Portfolio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
