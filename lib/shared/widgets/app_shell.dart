import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexForLocation(location);

    return Scaffold(
      body: Column(
        children: [
          const _DemoBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _goToTab(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '研究工作台',
          ),
          NavigationDestination(
            icon: Icon(Icons.filter_alt_outlined),
            selectedIcon: Icon(Icons.filter_alt),
            label: '條件篩選',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats),
            label: '策略研究',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: '研究日記',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/screener')) {
      return 1;
    }
    if (location.startsWith('/backtest')) {
      return 2;
    }
    if (location.startsWith('/journal')) {
      return 3;
    }
    if (location.startsWith('/settings')) {
      return 4;
    }
    return 0;
  }

  void _goToTab(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        return;
      case 1:
        context.go('/screener');
        return;
      case 2:
        context.go('/backtest');
        return;
      case 3:
        context.go('/journal');
        return;
      case 4:
        context.go('/settings');
        return;
    }
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: const Color(0xFFFFFBEB),
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFF3D08A)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Demo 版本｜目前使用模擬資料',
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7A4B00),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showDisclaimer(context),
                child: const Text('免責聲明'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisclaimer(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('免責聲明'),
          content: const Text(
            '本 App 提供之資訊僅供研究與教育用途，目前使用模擬資料，不構成任何投資建議、買賣建議或收益保證。使用者應自行判斷並承擔投資風險。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('我知道了'),
            ),
          ],
        );
      },
    );
  }
}
