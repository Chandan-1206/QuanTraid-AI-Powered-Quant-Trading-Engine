import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/prediction_model.dart';
import 'dart:math';

class ResultScreen extends StatefulWidget {
  final PredictionResponse prediction;

  const ResultScreen({super.key, required this.prediction});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _showMondaysOnly = false;

  Color _getSignalColor(String signal) {
    if (signal.contains('BUY')) return AppColors.profit;
    if (signal.contains('SELL')) return AppColors.loss;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    Color overallColor = _getSignalColor(widget.prediction.finalSignal);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Dashboard Hit
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: overallColor.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: overallColor.withOpacity(0.3), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(widget.prediction.stock, style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 8),
                      Text(
                        '₹${widget.prediction.currentPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMiniStat('Signal', widget.prediction.finalSignal, overallColor),
                          _buildMiniStat('Confidence', '${(widget.prediction.confidence * 100).toStringAsFixed(1)}%',
                              widget.prediction.confidence > 0.75 ? AppColors.profit : AppColors.warning),
                          _buildMiniStat('Risk', widget.prediction.riskLevel,
                              widget.prediction.riskLevel == 'High' ? AppColors.loss : AppColors.primary),
                          _buildMiniStat('Trend', widget.prediction.trend,
                              widget.prediction.trend == 'BULLISH' ? AppColors.profit : (widget.prediction.trend == 'BEARISH' ? AppColors.loss : Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // AI Synthesis Section
            _buildSectionHeader('AI Synthesis & Decision Breakdown'),
            _buildAIExplanation(),

            // --- TFT SHORT TERM ANALYSIS ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TFT Short-Term Forecast', style: Theme.of(context).textTheme.titleLarge),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleButton('All Days', !_showMondaysOnly),
                        _buildToggleButton('Mondays Only', _showMondaysOnly),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            _buildChartContainer(child: _buildPriceWithBoundsChart()),

            // --- NEW TOP OPPORTUNITIES SECTION ---
            _buildSectionHeader('Top Opportunities'),
            _buildTopOpportunitiesSection(),

            // --- NEW MONDAY STRATEGY SECTION ---
            _buildSectionHeader('Monday Strategy'),
            _buildMondayStrategySection(),

            // 2. Cumulative Return Simulator Curve
            _buildSectionHeader('Cumulative Return Projection'),
            _buildChartContainer(child: _buildCumulativeReturnChart()),

            // 3. Volatility / Trend Strength Histogram
            _buildSectionHeader('Volatility Profile'),
            _buildChartContainer(child: _buildVolatilityChart()),
            
            // 4. Signal Heatmap
            _buildSectionHeader('Signal Timeline'),
            _buildSignalHeatmap(),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showMondaysOnly = label == 'Mondays Only';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceBar(double confidence, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Confidence', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('${(confidence * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildTopOpportunitiesSection() {
    final ops = widget.prediction.topOpportunities;
    if (ops.isEmpty) return const SizedBox();

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: ops.length,
      itemBuilder: (context, index) {
        final pt = ops[index];
        final Color sColor = _getSignalColor(pt.signal);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sColor.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(DateFormat('MMM').format(pt.date).toUpperCase(), style: TextStyle(fontSize: 10, color: sColor, fontWeight: FontWeight.bold)),
                    Text(DateFormat('dd').format(pt.date), style: TextStyle(fontSize: 18, color: sColor, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₹${pt.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(pt.signal, style: TextStyle(color: sColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Return: ${(pt.predictedReturn * 100).toStringAsFixed(2)}%', style: TextStyle(fontSize: 12, color: pt.predictedReturn >= 0 ? AppColors.profit : AppColors.loss)),
                    const SizedBox(height: 8),
                    _buildConfidenceBar(pt.confidence, sColor),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMondayStrategySection() {
    final mondays = widget.prediction.mondayPredictions;
    if (mondays.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('No upcoming Monday signals available.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: mondays.length,
      itemBuilder: (context, index) {
        final pt = mondays[index];
        final bool isStrong = pt.priority;
        final Color sColor = _getSignalColor(pt.signal);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: isStrong ? Border.all(color: sColor.withOpacity(0.5), width: 1) : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(DateFormat('MMM').format(pt.date).toUpperCase(), style: TextStyle(fontSize: 10, color: sColor, fontWeight: FontWeight.bold)),
                    Text(DateFormat('dd').format(pt.date), style: TextStyle(fontSize: 18, color: sColor, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('₹${pt.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (isStrong) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: sColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                            child: Text('Weekly Opportunity', style: TextStyle(fontSize: 9, color: sColor, fontWeight: FontWeight.bold)),
                          )
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Return: ${(pt.predictedReturn * 100).toStringAsFixed(2)}%', style: TextStyle(fontSize: 12, color: pt.predictedReturn >= 0 ? AppColors.profit : AppColors.loss)),
                    const SizedBox(height: 8),
                    _buildConfidenceBar(pt.confidence, sColor),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(isStrong ? 'STRONG ${pt.signal}' : pt.signal, style: TextStyle(color: sColor, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, Color vColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: vColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(value, style: TextStyle(color: vColor, fontWeight: FontWeight.w800, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildAIExplanation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Intelligent Synthesis', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.prediction.explanation,
                style: const TextStyle(height: 1.5),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(),
              ),
              Text('Model Breakdown', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Model 1A (TFT)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Base Signal: ${widget.prediction.model1aBaseSignal}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Model 1B (Heuristics)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Momentum: ${(widget.prediction.model1b.momentumScore * 100).toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        Text('Volatility: ${(widget.prediction.model1b.volatilityScore * 100).toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        Text('Strength: ${widget.prediction.model1b.strength}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildChartContainer({required Widget child}) {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(top: 24, right: 24, bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Theme.of(context).cardTheme.shape is RoundedRectangleBorder
            ? Border.all(color: (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).side.color)
            : null,
      ),
      child: child,
    );
  }

  Widget _buildPriceWithBoundsChart() {
    List<PredictionPoint> data = _showMondaysOnly ? widget.prediction.mondayPredictions : widget.prediction.shortTermPredictions;
    if (data.isEmpty) return const Center(child: Text('No data'));

    List<FlSpot> priceSpots = [];
    List<FlSpot> upperSpots = [];
    List<FlSpot> lowerSpots = [];
    
    double minV = widget.prediction.currentPrice;
    double maxV = widget.prediction.currentPrice;

    for (int i = 0; i < data.length; i++) {
        var p = data[i];
        priceSpots.add(FlSpot(i.toDouble(), p.price));
        upperSpots.add(FlSpot(i.toDouble(), p.upperBound));
        lowerSpots.add(FlSpot(i.toDouble(), p.lowerBound));
        
        minV = min(minV, p.lowerBound);
        maxV = max(maxV, p.upperBound);
    }

    minV = minV * 0.98;
    maxV = maxV * 1.02;

    if (minV >= maxV) {
      minV -= 1.0;
      maxV += 1.0;
    }

    return LineChart(
      LineChartData(
        minY: minV,
        maxY: maxV,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
             getTooltipItems: (touchedSpots) {
               return touchedSpots.map((spot) {
                 final pt = data[spot.x.toInt()];
                 return LineTooltipItem(
                   '${DateFormat('MMM dd').format(pt.date)}\n₹${pt.price.toStringAsFixed(2)}\nRet: ${(pt.predictedReturn * 100).toStringAsFixed(2)}% | Conf: ${(pt.confidence * 100).toStringAsFixed(0)}%\n${pt.signal}',
                   const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                 );
               }).toList();
             }
          )
        ),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
             sideTitles: SideTitles(
                showTitles: true,
                interval: _showMondaysOnly ? 1 : 5,
                getTitlesWidget: (v, meta) {
                    if (v < 0 || v >= data.length) return const Text('');
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(DateFormat('dd/MM').format(data[v.toInt()].date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    );
                }
             )
          )
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Upper bound
          LineChartBarData(
            spots: upperSpots,
            isCurved: true,
            color: Colors.transparent,
            barWidth: 0,
            dotData: const FlDotData(show: false),
          ),
          // Lower bound with BarAreaData filling to upper
          LineChartBarData(
            spots: lowerSpots,
            isCurved: true,
            color: Colors.transparent,
            barWidth: 0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: !_showMondaysOnly, // Hide area when Mondays only to avoid weird overlapping
              color: AppColors.primary.withOpacity(0.15),
              cutOffY: maxV,
              applyCutOffY: false,
            ),
          ),
          // Price central line
          LineChartBarData(
            spots: priceSpots,
            isCurved: !_showMondaysOnly,
            color: AppColors.secondary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
               show: true,
               checkToShowDot: (spot, barData) {
                  if (_showMondaysOnly) return true;
                  final pt = data[spot.x.toInt()];
                  return pt.date.weekday == DateTime.monday || pt.signal == 'BUY' || pt.signal == 'SELL';
               },
               getDotPainter: (spot, percent, barData, index) {
                  final pt = data[spot.x.toInt()];
                  final isMonday = pt.date.weekday == DateTime.monday;
                  final isPriority = pt.priority;
                  
                  return FlDotCirclePainter(
                    radius: isPriority ? 6 : (isMonday ? 5 : 4),
                    color: _getSignalColor(pt.signal),
                    strokeWidth: isPriority ? 3 : 2,
                    strokeColor: Colors.white,
                  );
               }
            ),
          )
        ],
      )
    );
  }

  Widget _buildCumulativeReturnChart() {
    List<FlSpot> spots = [];
    double minReturn = 0;
    double maxReturn = 0;
    var data = widget.prediction.shortTermPredictions;
    if (data.isEmpty) return const Center(child: Text('No data'));

    for (int i = 0; i < data.length; i++) {
        double r = data[i].cumulativeReturn;
        spots.add(FlSpot(i.toDouble(), r));
        minReturn = min(minReturn, r);
        maxReturn = max(maxReturn, r);
    }

    if (maxReturn == minReturn) {
      if (maxReturn == 0) {
        maxReturn = 1.0;
        minReturn = -1.0;
      } else {
        maxReturn += 1.0;
        minReturn -= 1.0;
      }
    } else {
      if (maxReturn <= 0) maxReturn = 1.0;
      if (minReturn >= 0) minReturn = -1.0;
    }

    return LineChart(
      LineChartData(
        minY: minReturn * 1.2,
        maxY: maxReturn * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1, dashArray: [5,5])
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: spots.last.y >= 0 ? AppColors.profit : AppColors.loss,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: (spots.last.y >= 0 ? AppColors.profit : AppColors.loss).withOpacity(0.2),
            )
          )
        ]
      )
    );
  }

  Widget _buildVolatilityChart() {
    List<BarChartGroupData> groups = [];
    double maxVol = 0;
    var data = widget.prediction.shortTermPredictions;
    if (data.isEmpty) return const Center(child: Text('No data'));

    for (int i = 0; i < data.length; i++) {
        double v = data[i].volatility;
        maxVol = max(maxVol, v);
        groups.add(
            BarChartGroupData(
                x: i,
                barRods: [
                    BarChartRodData(
                        toY: v,
                        color: v > 1.2 ? AppColors.loss : AppColors.warning,
                        width: 4,
                        borderRadius: BorderRadius.circular(2)
                    )
                ]
            )
        );
    }

    if (maxVol <= 0) maxVol = 1.0;

    return BarChart(
       BarChartData(
          maxY: maxVol * 1.2,
          barGroups: groups,
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
       )
    );
  }

  Widget _buildSignalHeatmap() {
    var data = widget.prediction.shortTermPredictions;
    if (data.isEmpty) return const SizedBox();
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
         scrollDirection: Axis.horizontal,
         itemCount: data.length,
         itemBuilder: (context, index) {
            final pt = data[index];
            return Tooltip(
               message: '${DateFormat('MMM dd').format(pt.date)}: ${pt.signal}',
               child: Container(
                  width: 12,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                     color: _getSignalColor(pt.signal),
                     borderRadius: BorderRadius.circular(2)
                  ),
               ),
            );
         }
      ),
    );
  }
}
