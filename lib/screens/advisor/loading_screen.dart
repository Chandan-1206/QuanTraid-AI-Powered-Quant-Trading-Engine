import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../data/api_service.dart';
import '../../models/prediction_model.dart';
import 'result_screen.dart';

class LoadingScreen extends StatefulWidget {
  final String stock;
  final String duration;

  const LoadingScreen({
    super.key,
    required this.stock,
    required this.duration,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final response = await ApiService().getPrediction(widget.stock, widget.duration);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResultScreen(prediction: response),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _controller,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.5),
                    width: 4,
                  ),
                ),
                child: const Icon(
                  Icons.memory,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'AI Analyzing...',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Running Temporal Fusion Transformer Model',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
