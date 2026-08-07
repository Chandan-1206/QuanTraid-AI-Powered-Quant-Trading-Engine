enum RiskProfile { low, medium, high }

class Strategy {
  final String id;
  final String name;
  final String description;
  final double confidenceScore;
  final double expectedReturn;
  final double riskScore;
  final double winRate;
  final List<String> tags;
  final RiskProfile risk;
  final String type; // 'Trend Following', 'Mean Reversion', etc.

  Strategy({
    required this.id,
    required this.name,
    required this.description,
    required this.confidenceScore,
    required this.expectedReturn,
    required this.riskScore,
    required this.winRate,
    required this.tags,
    required this.risk,
    required this.type,
  });
}
