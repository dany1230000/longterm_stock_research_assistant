import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF1D4E89);
  static const _secondary = Color(0xFF2A9D8F);
  static const _surface = Color(0xFFF6F8FB);
  static const _warning = Color(0xFFE9A23B);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: _primary,
      secondary: _secondary,
      surface: Colors.white,
      error: const Color(0xFFC2410C),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _surface,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: _surface,
        foregroundColor: Color(0xFF172033),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE1E7EF)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD8E0EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD8E0EA)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: _primary.withAlpha(31),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      extensions: const [
        ResearchColors(
          positive: Color(0xFF15803D),
          neutral: Color(0xFF64748B),
          warning: _warning,
          highRisk: Color(0xFFB42318),
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.dark,
      ),
      extensions: const [
        ResearchColors(
          positive: Color(0xFF4ADE80),
          neutral: Color(0xFF94A3B8),
          warning: _warning,
          highRisk: Color(0xFFFCA5A5),
        ),
      ],
    );
  }
}

class ResearchColors extends ThemeExtension<ResearchColors> {
  const ResearchColors({
    required this.positive,
    required this.neutral,
    required this.warning,
    required this.highRisk,
  });

  final Color positive;
  final Color neutral;
  final Color warning;
  final Color highRisk;

  @override
  ResearchColors copyWith({
    Color? positive,
    Color? neutral,
    Color? warning,
    Color? highRisk,
  }) {
    return ResearchColors(
      positive: positive ?? this.positive,
      neutral: neutral ?? this.neutral,
      warning: warning ?? this.warning,
      highRisk: highRisk ?? this.highRisk,
    );
  }

  @override
  ResearchColors lerp(ThemeExtension<ResearchColors>? other, double t) {
    if (other is! ResearchColors) {
      return this;
    }
    return ResearchColors(
      positive: Color.lerp(positive, other.positive, t) ?? positive,
      neutral: Color.lerp(neutral, other.neutral, t) ?? neutral,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      highRisk: Color.lerp(highRisk, other.highRisk, t) ?? highRisk,
    );
  }
}
