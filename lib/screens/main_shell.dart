import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'allowance_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _refreshTick = 0;

  void _onSettingsSaved() {
    if (!mounted) return;
    setState(() {
      _refreshTick = _refreshTick + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      DashboardScreen(key: ValueKey<int>(_refreshTick)),
      AllowanceScreen(key: ValueKey<int>(_refreshTick)),
      SettingsScreen(
        isFirstTime: false,
        onSaved: _onSettingsSaved,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: AppColors.primary.withValues(alpha: 0.15),
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: AppColors.primary);
              }
              return const IconThemeData(color: AppColors.textMuted);
            }),
            labelTextStyle:
                WidgetStateProperty.resolveWith<TextStyle>((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                );
              }
              return const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              );
            }),
          ),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.cardBorder,
                  width: 1,
                ),
              ),
            ),
            child: NavigationBar(
              height: 68,
              backgroundColor: AppColors.bgDark,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.payments_outlined),
                  selectedIcon: Icon(Icons.payments_rounded),
                  label: 'Allowance',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}