import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../widgets/kems_ui.dart';
import 'data_screen.dart';
import 'energy_flow_screen.dart';
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
      EnergyFlowScreen(controller: widget.controller),
      DataScreen(controller: widget.controller),
      ReportsScreen(controller: widget.controller),
      NotificationsScreen(controller: widget.controller),
      SettingsScreen(controller: widget.controller),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const BrandTitle(),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: widget.controller.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub),
            label: 'Flow',
          ),
          NavigationDestination(
            icon: Icon(Icons.dataset_outlined),
            selectedIcon: Icon(Icons.dataset),
            label: 'Data',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
