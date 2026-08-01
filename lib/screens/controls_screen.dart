import 'package:flutter/material.dart';
import '../state/app_controller.dart';

class ControlsScreen extends StatelessWidget {
  const ControlsScreen({super.key, required this.controller});
  final AppController controller;

  String _value(String id, {String fallback = '—'}) {
    final e = controller.entity(id);
    if (e == null || ['unknown', 'unavailable'].contains(e.state)) return fallback;
    return '${e.state}${e.unit.isEmpty ? '' : ' ${e.unit}'}';
  }

  @override
  Widget build(BuildContext context) {
    final m = controller.mapping;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('KEMS Status', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text('This release is intentionally read-only. KEMS v0.6 is in Observe → Learn, and no control entities or services are exposed yet.'),
      const SizedBox(height: 16),
      Card(child: Column(children: [
        ListTile(leading: const Icon(Icons.route), title: const Text('Current phase'), trailing: Text(_value(m.phase))),
        ListTile(leading: const Icon(Icons.psychology), title: const Text('Learning confidence'), trailing: Text(_value(m.learningConfidence))),
        ListTile(leading: const Icon(Icons.science), title: const Text('Simulation'), trailing: Text(controller.isOn(m.simulationReady) ? 'Ready' : 'Not ready')),
        ListTile(leading: const Icon(Icons.account_balance_wallet), title: const Text('ROI prediction'), trailing: Text(controller.isOn(m.roiReady) ? 'Ready' : 'Learning')),
        ListTile(leading: const Icon(Icons.solar_power), title: const Text('System installed'), trailing: Text(controller.isOn(m.systemInstalled) ? 'Yes' : 'Proposal model')),
      ])),
      const SizedBox(height: 16),
      const Card(child: Padding(
        padding: EdgeInsets.all(18),
        child: Text('Controls will appear automatically in a later app release when the Home Assistant integration publishes supported KEMS services or control entities. The app will never command Octopus, Ohme, FoxESS or other equipment directly.'),
      )),
    ]);
  }
}
