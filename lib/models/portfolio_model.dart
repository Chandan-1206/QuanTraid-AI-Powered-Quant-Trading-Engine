class PortfolioSummary {
  final double totalBalance;
  final double dailyPnL;
  final double dailyPnLPercent;
  final double strategyConfidence;
  final double marketSentiment;
  final List<Map<String, dynamic>> allocation; // e.g., [{'asset': 'BTC', 'weight': 40}]

  PortfolioSummary({
    required this.totalBalance,
    required this.dailyPnL,
    required this.dailyPnLPercent,
    required this.strategyConfidence,
    required this.marketSentiment,
    required this.allocation,
  });
}
