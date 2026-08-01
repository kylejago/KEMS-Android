import 'package:flutter/material.dart';
import '../models/ha_entity.dart';
import '../state/app_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final m = controller.mapping;
    final alerts = <({IconData icon, String title, String detail, bool warning})>[
      if (controller.isOn(m.gridImportOutsideCheap))
        (icon: Icons.warning_amber_rounded, title: 'Grid import outside cheap period', detail: 'KEMS has detected standard-rate grid import.', warning: true),
      if (controller.isOn(m.cheapPeriodConfirmed))
        (icon: Icons.bolt, title: 'Cheap period confirmed', detail: 'KEMS has confirmed the current cheap-energy window.', warning: false),
      if (controller.isOn(m.evCharging))
        (icon: Icons.electric_car, title: 'EV charging', detail: 'Charging power: ${_value(m.evPower)}', warning: false),
      if (!controller.isOn(m.learningReady))
        (icon: Icons.psychology, title: 'KEMS is learning', detail: 'Confidence: ${_value(m.learningConfidence)}', warning: false),
      if (!controller.isOn(m.simulationReady))
        (icon: Icons.science, title: 'Simulation not ready', detail: 'More history is required before simulation results are reliable.', warning: false),
    ];

    final dynamicEvents = controller.kemsEntities.where(_isEventLike).toList()
      ..sort((a, b) => (b.lastChanged ?? DateTime(1970)).compareTo(a.lastChanged ?? DateTime(1970)));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Alerts & status', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Live KEMS conditions derived from Home Assistant. Push notifications remain managed by Home Assistant.'),
        const SizedBox(height: 16),
        ...alerts.map((a) => Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(a.icon)),
            title: Text(a.title),
            subtitle: Text(a.detail),
            trailing: a.warning ? Icon(Icons.priority_high, color: Theme.of(context).colorScheme.error) : null,
          ),
        )),
        Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.tips_and_updates)),
          title: const Text('Current advice'),
          subtitle: Text(_value(m.advice, fallback: 'No advice available yet.')),
        )),
        if (dynamicEvents.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Recent KEMS entities', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...dynamicEvents.take(20).map((e) => Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_none),
              title: Text(e.friendlyName),
              subtitle: Text(e.state),
            ),
          )),
        ],
      ],
    );
  }

  bool _isEventLike(HaEntity e) {
    final id = e.entityId.toLowerCase();
    return id.contains('advice') || id.contains('status') || id.contains('ready') || id.contains('outside_cheap');
  }

  String _value(String id, {String fallback = '—'}) {
    final e = controller.entity(id);
    if (e == null || ['unknown', 'unavailable'].contains(e.state)) return fallback;
    return '${e.state}${e.unit.isEmpty ? '' : ' ${e.unit}'}';
  }
}
