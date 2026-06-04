import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/backtest/backtest_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/journal/journal_screen.dart';
import 'features/screener/screener_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/stock_detail/stock_detail_screen.dart';
import 'shared/widgets/app_shell.dart';

GoRouter createAppRouter({String initialLocation = '/dashboard'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/screener',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ScreenerScreen(),
            ),
          ),
          GoRoute(
            path: '/backtest',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BacktestScreen(),
            ),
          ),
          GoRoute(
            path: '/journal',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: JournalScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/stocks/:symbol',
            builder: (context, state) {
              final symbol = state.pathParameters['symbol'] ?? '';
              return StockDetailScreen(symbol: symbol);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('頁面狀態')),
      body: Center(
        child: Text(
          '找不到指定頁面',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ),
  );
}
