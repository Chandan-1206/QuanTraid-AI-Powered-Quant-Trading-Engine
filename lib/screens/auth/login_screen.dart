import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_colors.dart';
import '../../widgets/action_button.dart';
import '../../widgets/glass_card.dart';
import '../../navigation/main_navigation.dart';
import '../dashboard/dashboard_screen.dart';
import '../strategy_generator/strategy_generator_screen.dart';
import '../backtest/backtest_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../profile/profile_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 40),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Login to manage your AI trading strategies.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 50),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 20),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline, size: 20),
                  suffixIcon: Icon(Icons.visibility_off_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ActionButton(
                  label: 'Login',
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainNavigation(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  'OR CONTINUE WITH',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _SocialTile(icon: FontAwesomeIcons.google),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _SocialTile(icon: FontAwesomeIcons.apple),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
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
}

class _SocialTile extends StatelessWidget {
  final IconData icon;
  const _SocialTile({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: FaIcon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
