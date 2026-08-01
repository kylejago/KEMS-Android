import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../theme/kems_theme.dart';
import 'dashboard_screen.dart';
import 'simulation_screen.dart';

enum DataMode { live, simulation }

class DataScreen extends StatefulWidget {
  const DataScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  DataMode mode = DataMode.live;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<DataMode>(
            segments: const [
              ButtonSegment(
                value: DataMode.live,
                icon: Icon(Icons.sensors),
                label: Text('Live'),
              ),
              ButtonSegment(
                value: DataMode.simulation,
                icon: Icon(Icons.science),
                label: Text('Simulation'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (selection) {
              setState(() => mode = selection.first);
            },
            style: ButtonStyle(
              side: WidgetStatePropertyAll(
                BorderSide(color: KemsTheme.green.withValues(alpha: .25)),
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: mode == DataMode.live ? 0 : 1,
            children: [
              DashboardScreen(controller: widget.controller),
              SimulationScreen(controller: widget.controller),
            ],
          ),
        ),
      ],
    );
  }
}
