import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import 'controls_screen.dart';
import 'dashboard_screen.dart';
import 'notifications_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});
  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(controller: widget.controller),
      ReportsScreen(controller: widget.controller),
      NotificationsScreen(controller: widget.controller),
      ControlsScreen(controller: widget.controller),
      SettingsScreen(controller: widget.controller),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.bolt), SizedBox(width: 8), Text('KEMS')]),
        actions: [IconButton(onPressed: widget.controller.refresh, icon: const Icon(Icons.refresh))],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.query_stats), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Controls'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
