import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../widgets/metric_card.dart';
import '../widgets/status_pill.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller});
  final AppController controller;

  String _value(String id, {String fallback = '—'}) {
    final entity = controller.entity(id);
    if (entity == null || ['unknown', 'unavailable'].contains(entity.state)) {
      return fallback;
    }
    return '${entity.state}${entity.unit.isEmpty ? '' : ' ${entity.unit}'}';
  }

  @override
  Widget build(BuildContext context) {
    final m = controller.mapping;
    final cheap = controller.isOn(m.cheapPeriodConfirmed) || controller.isOn(m.offPeak);
    final warning = controller.isOn(m.gridImportOutsideCheap);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: Text('KEMS Overview', style: Theme.of(context).textTheme.headlineMedium)),
            StatusPill(label: controller.connected ? 'Live' : 'Offline', active: controller.connected),
          ]),
          const SizedBox(height: 6),
          Text('${_value(m.phase)} • ${_value(m.status)}'),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(cheap ? Icons.bolt : Icons.schedule)),
              title: Text(cheap ? 'Cheap period confirmed' : 'Standard-rate period'),
              subtitle: Text('Now ${_value(m.currentRate)} • Next ${_value(m.nextRate)}'),
              trailing: warning ? const Icon(Icons.warning_amber_rounded) : null,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 4 : 2,
            childAspectRatio: 1.12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              MetricCard(title: 'Grid import', value: _value(m.gridImport), subtitle: _value(m.gridFlowDirection), icon: Icons.electrical_services),
              MetricCard(title: 'Grid export', value: _value(m.gridExport), icon: Icons.upload),
              MetricCard(title: 'Home', value: _value(m.houseLoad), icon: Icons.home),
              MetricCard(title: 'Battery', value: _value(m.batterySoc), subtitle: _value(m.batteryPower), icon: Icons.battery_charging_full),
              MetricCard(title: 'EV', value: _value(m.evPower), subtitle: 'SOC ${_value(m.evSoc)}', icon: Icons.electric_car),
              MetricCard(title: 'Data quality', value: _value(m.dataQuality), subtitle: '${_value(m.historySamples)} samples', icon: Icons.verified),
              MetricCard(title: 'Learning', value: _value(m.learningConfidence), subtitle: controller.isOn(m.learningReady) ? 'Ready' : 'Collecting data', icon: Icons.psychology),
              MetricCard(title: 'Until off-peak', value: _value(m.predictedEnergyUntilOffPeak), subtitle: _value(m.nextOffPeakStart), icon: Icons.nightlight_round),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('KEMS advice', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(_value(m.advice, fallback: 'KEMS is collecting enough data to form advice.'), style: Theme.of(context).textTheme.bodyLarge),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
