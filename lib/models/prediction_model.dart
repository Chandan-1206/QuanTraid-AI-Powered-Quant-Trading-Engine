class PredictionPoint {
  final DateTime date;
  final double price;
  final double upperBound;
  final double lowerBound;
  final String signal;
  final double confidence;
  final String advice;
  final double volatility;
  final double trendStrength;
  final double cumulativeReturn;
  final bool priority; // Added for Monday strategy
  final double predictedReturn;
  final double score;
  final String dailyTrend;

  PredictionPoint({
    required this.date,
    required this.price,
    required this.upperBound,
    required this.lowerBound,
    required this.signal,
    required this.confidence,
    required this.advice,
    required this.volatility,
    required this.trendStrength,
    required this.cumulativeReturn,
    this.priority = false,
    this.predictedReturn = 0.0,
    this.score = 0.0,
    this.dailyTrend = "SIDEWAYS",
  });

  factory PredictionPoint.fromJson(Map<String, dynamic> json) {
    return PredictionPoint(
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      price: json['price']?.toDouble() ?? 0.0,
      upperBound: json['upper_bound']?.toDouble() ?? json['price']?.toDouble() ?? 0.0,
      lowerBound: json['lower_bound']?.toDouble() ?? json['price']?.toDouble() ?? 0.0,
      signal: json['signal'] ?? 'HOLD',
      confidence: json['confidence']?.toDouble() ?? 0.0,
      advice: json['advice'] ?? '',
      volatility: json['volatility']?.toDouble() ?? 0.0,
      trendStrength: json['trend_strength']?.toDouble() ?? 0.0,
      cumulativeReturn: json['cumulative_return']?.toDouble() ?? 0.0,
      priority: json['priority'] ?? false,
      predictedReturn: json['predicted_return']?.toDouble() ?? 0.0,
      score: json['score']?.toDouble() ?? 0.0,
      dailyTrend: json['daily_trend'] ?? "SIDEWAYS",
    );
  }
}

class Model1BData {
  final double momentumScore;
  final double volatilityScore;
  final String strength;

  Model1BData({
    required this.momentumScore,
    required this.volatilityScore,
    required this.strength,
  });

  factory Model1BData.fromJson(Map<String, dynamic> json) {
    return Model1BData(
      momentumScore: json['momentum_score']?.toDouble() ?? 0.0,
      volatilityScore: json['volatility_score']?.toDouble() ?? 0.0,
      strength: json['strength'] ?? 'WEAK',
    );
  }
}

class LongTermPredictions {
  final List<PredictionPoint> m1;
  final List<PredictionPoint> m3;
  final List<PredictionPoint> m6;

  LongTermPredictions({
    required this.m1,
    required this.m3,
    required this.m6,
  });

  factory LongTermPredictions.fromJson(Map<String, dynamic> json) {
    var l1m = json['1M'] as List? ?? [];
    var l3m = json['3M'] as List? ?? [];
    var l6m = json['6M'] as List? ?? [];
    return LongTermPredictions(
      m1: l1m.map((i) => PredictionPoint.fromJson(i)).toList(),
      m3: l3m.map((i) => PredictionPoint.fromJson(i)).toList(),
      m6: l6m.map((i) => PredictionPoint.fromJson(i)).toList(),
    );
  }
}

class PredictionResponse {
  final String stock;
  final double currentPrice;
  final String finalSignal;
  final double confidence;
  final String riskLevel;
  final String trend;
  final String explanation;
  final List<PredictionPoint> shortTermPredictions;
  final List<PredictionPoint> mondayPredictions;
  final List<PredictionPoint> topOpportunities; // Added
  final LongTermPredictions longTermPredictions;
  final String model1aBaseSignal;
  final Model1BData model1b;

  // Keep this for backward compatibility if other places use it directly
  List<PredictionPoint> get predictions => shortTermPredictions;

  PredictionResponse({
    required this.stock,
    required this.currentPrice,
    required this.finalSignal,
    required this.confidence,
    required this.riskLevel,
    required this.trend,
    required this.explanation,
    required this.shortTermPredictions,
    required this.mondayPredictions,
    required this.topOpportunities,
    required this.longTermPredictions,
    required this.model1aBaseSignal,
    required this.model1b,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    var shortTermJson = json['short_term_predictions'] as List? ?? [];
    var mondayJson = json['monday_predictions'] as List? ?? [];
    var topJson = json['top_opportunities'] as List? ?? [];
    var longTermJson = json['long_term_predictions'] ?? {};
    
    // Fallback if older API format is received
    if (shortTermJson.isEmpty && json['model_1a'] != null && json['model_1a']['predictions'] != null) {
        shortTermJson = json['model_1a']['predictions'];
    }

    List<PredictionPoint> shortList = shortTermJson.map((i) => PredictionPoint.fromJson(i)).toList();
    List<PredictionPoint> mondayList = mondayJson.map((i) => PredictionPoint.fromJson(i)).toList();
    List<PredictionPoint> topList = topJson.map((i) => PredictionPoint.fromJson(i)).toList();

    return PredictionResponse(
      stock: json['stock'] ?? '',
      currentPrice: json['current_price']?.toDouble() ?? 0.0,
      finalSignal: json['final_signal'] ?? 'HOLD',
      confidence: json['confidence']?.toDouble() ?? 0.0,
      riskLevel: json['risk_level'] ?? 'Medium',
      trend: json['trend'] ?? 'NEUTRAL',
      explanation: json['explanation'] ?? '',
      shortTermPredictions: shortList,
      mondayPredictions: mondayList,
      topOpportunities: topList,
      longTermPredictions: LongTermPredictions.fromJson(longTermJson),
      model1aBaseSignal: json['model_1a']?['base_signal'] ?? 'HOLD',
      model1b: Model1BData.fromJson(json['model_1b'] ?? {}),
    );
  }
}
