import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/action_button.dart';

class AutomatedTradingScreen extends StatefulWidget {
  const AutomatedTradingScreen({super.key});

  @override
  State<AutomatedTradingScreen> createState() => _AutomatedTradingScreenState();
}

class _AutomatedTradingScreenState extends State<AutomatedTradingScreen> {
  bool _isLive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Simulation Control',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your AI bots and automated strategies.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              _buildLiveStatusCard(),
              const SizedBox(height: 32),
              const SectionHeader(title: 'Active Simulation Bots'),
              _buildActiveBots(),
              const SizedBox(height: 32),
              const SectionHeader(title: 'Live Execution Logs'),
              _buildLogsArea(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStatusCard() {
    return GlassCard(
      height: 100,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLive ? 'Simulation Active' : 'Simulation Paused',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isLive ? AppColors.profit : AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLive ? '3 bots currently executing trades.' : 'Enable to start AI-assisted trading.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _isLive,
            onChanged: (v) => setState(() => _isLive = v),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBots() {
    return Column(
      children: [
        _buildBotCard('Quas-Alpha v1', 'BTC/USDT', 'Running'),
        const SizedBox(height: 12),
        _buildBotCard('TrendMaster', 'NIFTY/INR', 'Paused'),
      ],
    );
  }

  Widget _buildBotCard(String name, String pair, String status) {
    final isRunning = status == 'Running';
    return GlassCard(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.smart_toy_outlined, color: isRunning ? AppColors.primary : AppColors.textMuted),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(pair, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          Text(
            status,
            style: TextStyle(color: isRunning ? AppColors.profit : AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsArea() {
    return GlassCard(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: ListView.separated(
        itemCount: 10,
        separatorBuilder: (context, index) => const Divider(color: Colors.white10),
        itemBuilder: (context, index) {
          return Text(
            '[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] BotQuas: Analysis complete for ${['BTC', 'ETH', 'TSLA'][index % 3]}. Signal: ${['BUY', 'HOLD'][index % 2]}.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontFamily: 'monospace'),
          );
        },
      ),
    );
  }
}
