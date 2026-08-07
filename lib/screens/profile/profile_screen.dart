import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildProfileHeader(),
              const SizedBox(height: 32),
              _buildPlanCard(),
              const SizedBox(height: 32),
              const SectionHeader(title: 'Account Settings'),
              _buildSettingsList(),
              const SizedBox(height: 32),
              _buildLogoutButton(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=quantraid'),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'David Sharma',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text(
          'david.sharma@example.com',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPlanCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pro AI Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Active until Dec 2024', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Upgrade', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return Column(
      children: [
        _buildSettingItem(Icons.security, 'Security', '2FA, Biometrics'),
        const SizedBox(height: 12),
        _buildSettingItem(Icons.analytics_outlined, 'Risk Profile', 'Medium-Aggressive'),
        const SizedBox(height: 12),
        _buildSettingItem(Icons.notifications_none, 'Notifications', 'Critical Alerts Only'),
        const SizedBox(height: 12),
        _buildSettingItem(Icons.color_lens_outlined, 'Appearance', 'Dark Mode'),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.loss,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Logout Account', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
