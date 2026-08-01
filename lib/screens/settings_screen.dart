import 'package:flutter/material.dart';
import '../state/app_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Card(child: Column(children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home Assistant'),
              subtitle: Text(controller.config?.normalizedBaseUrl ?? 'Not configured'),
            ),
            const ListTile(
              leading: Icon(Icons.security),
              title: Text('Authentication'),
              subtitle: Text('Long-Lived Access Token stored using Android encrypted storage'),
            ),
            ListTile(
              leading: const Icon(Icons.hub),
              title: const Text('Detected KEMS entities'),
              subtitle: Text('${controller.kemsEntities.length} sensors and binary sensors'),
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('KEMS Companion'),
              subtitle: Text('Version 1.2.1 • KEMS integration 0.6 compatible'),
            ),
          ])),
          const SizedBox(height: 16),
          ExpansionTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Entity diagnostics'),
            subtitle: const Text('Entities discovered live from Home Assistant'),
            children: controller.kemsEntities.map((e) => ListTile(
              dense: true,
              title: Text(e.friendlyName),
              subtitle: Text(e.entityId),
              trailing: Text(e.state, overflow: TextOverflow.ellipsis),
            )).toList(),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: controller.logOut,
            icon: const Icon(Icons.logout),
            label: const Text('Change Home Assistant server'),
          ),
        ],
      );
}
