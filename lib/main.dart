import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'providers/app_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const QuanTraidApp(),
    ),
  );
}

class QuanTraidApp extends StatelessWidget {
  const QuanTraidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: appProvider.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}
