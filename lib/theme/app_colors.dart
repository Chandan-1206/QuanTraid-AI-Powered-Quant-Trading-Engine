import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0B0F14); // Deep black-blue
  static const Color surface = Color(0xFF121821);
  static const Color surfaceLight = Color(0xFF161D26); // Cards
  
  // Accents
  static const Color primary = Color(0xFF3B82F6); // Blue Confidence highlight
  static const Color secondary = Color(0xFF22C55E); // Green
  static const Color accent = Color(0xFF1E293B); 
  
  // Financial Colors
  static const Color profit = Color(0xFF22C55E); // Soft modern green
  static const Color loss = Color(0xFFEF4444); // Not too bright red
  static const Color warning = Color(0xFFFACC15); // Subtle warm yellow
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAB4C3);
  static const Color textMuted = Color(0xFF6B7280);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const Color border = Color(0xFF1F2937);
}
