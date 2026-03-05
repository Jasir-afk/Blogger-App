import 'package:flutter/material.dart';

class AppColors {
  // ── Theme / Brand colors ──────────────────────────────────────────────
  static const Color scaffoldBg = Color(0xFF111827); // Very dark gray/black
  static const Color cardBg = Color(0xFF1F2937); // Darker surfaces
  static const Color borderColor = Color(0xFF374151); // Borders

  // Vibrant Pink/Purple Gradient (Matching Screenshot)
  static const Color primaryColor = Color(0xFFD946EF); // Bright Fuchsia
  static const Color accentColor = Color(0xFFF472B6); // Vibrant Pink
  static const Color secondaryColor = Color(0xFF8B5CF6); // Deep Violet

  // Text Colors
  static const Color titleColor = Colors.white;
  static const Color subtitleColor = Color(0xFF9CA3AF);
  static const Color labelColor = Color(0xFFD1D5DB);
  static const Color iconColor = Color(0xFF9CA3AF);
  static const Color hintColor = Color(0xFF6B7280);

  // Status Colors
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color dangerColor = Color(0xFFDC2626);

  // Backward compatibility (old colors if needed elsewhere)
  static const Color redcolor = Color(0xFFFF0000);
  static const Color greencolor = Color(0xFF14AE5C);
}
