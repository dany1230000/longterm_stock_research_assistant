import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router.dart';
import 'services/app_theme_controller.dart';
import 'theme/app_theme.dart';

class LongTermStockResearchApp extends StatefulWidget {
  const LongTermStockResearchApp({super.key});

  @override
  State<LongTermStockResearchApp> createState() =>
      _LongTermStockResearchAppState();
}

class _LongTermStockResearchAppState extends State<LongTermStockResearchApp> {
  late final _router = createAppRouter();

  @override
  void initState() {
    super.initState();
    loadSavedThemeMode();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp.router(
          title: '00631L 正二研究室',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          locale: const Locale('zh', 'TW'),
          supportedLocales: const [
            Locale('zh', 'TW'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
        );
      },
    );
  }
}
