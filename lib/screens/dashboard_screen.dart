import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../theme/kems_theme.dart';
import '../widgets/kems_ui.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final m = controller.mapping;
    final advice = controller.entity(m.advice)?.state ?? 'KEMS is observing your energy use';
    final phase = controller.entity(m.phase)?.state ?? 'Observe';
    final cheap = controller.isOn(m.cheapPeriodConfirmed);
    return KemsPage(children: [
      Row(children: [LivePill(connected: controller.connected), const Spacer(), Text('Updated ${_updated()}', style: const TextStyle(color: Colors.white38, fontSize: 11))]),
      const SizedBox(height: 14),
      KemsCard(
        glow: cheap ? KemsTheme.cyan : KemsTheme.green,
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: KemsTheme.green.withValues(alpha: .15), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.home_rounded, color: KemsTheme.green, size: 30)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cheap ? 'Cheap period active' : 'KEMS is $phase', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(advice, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60)),
          ])),
        ]),
      ),
      const SectionTitle('Live energy'),
      GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.35,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          MetricTile(label: 'Grid', value: displayEntity(controller, m.gridNetPower), caption: controller.entity(m.gridFlowDirection)?.state ?? 'Live flow', icon: Icons.electric_meter_outlined, color: KemsTheme.blue),
          MetricTile(label: 'Home', value: displayEntity(controller, m.houseLoad), caption: 'Current demand', icon: Icons.home_outlined, color: KemsTheme.purple),
          MetricTile(label: 'Battery', value: displayEntity(controller, m.batterySoc), caption: displayEntity(controller, m.batteryPower), icon: Icons.battery_charging_full, color: KemsTheme.green),
          MetricTile(label: 'EV (Ohme)', value: displayEntity(controller, m.evSoc), caption: displayEntity(controller, m.evPower), icon: Icons.electric_car_outlined, color: KemsTheme.cyan),
          MetricTile(label: 'Tariff', value: displayEntity(controller, m.currentRate, decimals: 3), caption: cheap ? 'Cheap rate' : 'Standard rate', icon: Icons.bolt, color: cheap ? KemsTheme.green : KemsTheme.amber),
          MetricTile(label: 'Solar', value: displayEntity(controller, m.solarPower), caption: 'Generation', icon: Icons.wb_sunny_outlined, color: KemsTheme.amber),
        ],
      ),
      const SectionTitle('Today'),
      KemsCard(child: Row(children: [
        _summary('Cost', displayEntity(controller, m.observedCostToday, decimals: 2)),
        _divider(),
        _summary('Saved', displayEntity(controller, m.simulatedSavingToday, decimals: 2), color: KemsTheme.green),
        _divider(),
        _summary('Imported', displayEntity(controller, m.observedGridImportToday)),
      ])),
      const SectionTitle('KEMS recommendation'),
      KemsCard(glow: KemsTheme.green, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.auto_awesome, color: KemsTheme.green),
        const SizedBox(width: 12),
        Expanded(child: Text(advice, style: const TextStyle(fontSize: 15, height: 1.4))),
      ])),
    ]);
  }

  Widget _summary(String label, String value, {Color color = Colors.white}) => Expanded(child: Column(children: [Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)), const SizedBox(height: 3), Text(label, style: const TextStyle(color: Colors.white45, fontSize: 11))]));
  Widget _divider() => Container(width: 1, height: 36, color: Colors.white10);
  String _updated() {
    final d = controller.lastUpdated;
    if (d == null) {
      return '—';
    }
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
