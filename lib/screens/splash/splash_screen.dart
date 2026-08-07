import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../theme/app_colors.dart';
import '../../navigation/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );

    _controller.forward();

    Future.delayed(AppConstants.splashDelay, () {
      if (mounted) {
        _showConfigDialog();
      }
    });
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainNavigation(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _showConfigDialog() {
    final TextEditingController ipController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Server Connection', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter backend IP if testing on physical device (e.g., 192.168.1.10) or leave blank for default (emulator).', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: ipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'IP Address',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (ipController.text.trim().isNotEmpty) {
                AppConstants.userApiBaseUrl = 'http://${ipController.text.trim()}:8000';
              }
              Navigator.pop(ctx);
              _navigateToMain();
            },
            child: const Text('Connect', style: TextStyle(color: AppColors.primary)),
          )
        ],
      ),
    );
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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        size: 80,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppConstants.appName.toUpperCase(),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        letterSpacing: 4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                      child: Text(
                        AppConstants.appTagline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
