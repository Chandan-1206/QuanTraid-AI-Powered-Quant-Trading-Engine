class TradeAsset {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final List<double> sparkline;
  final String category; // 'Stock', 'Crypto', 'Forex', 'Indices'

  TradeAsset({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.sparkline,
    required this.category,
  });
}
