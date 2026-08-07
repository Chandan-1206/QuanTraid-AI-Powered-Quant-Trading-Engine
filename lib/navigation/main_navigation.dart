import 'package:flutter/material.dart';
import '../screens/advisor/home_screen.dart';
import '../screens/portfolio/portfolio_screen.dart';
import '../screens/watchlist/watchlist_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../theme/app_colors.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PortfolioScreen(),
    const WatchlistScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Determine bottom nav bar color based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: isDark ? AppColors.surface : Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? AppColors.textSecondary : Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_rounded),
              label: 'Portfolio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_rounded),
              label: 'Watchlist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
