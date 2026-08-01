import 'package:flutter/material.dart';

import '../models/ha_entity.dart';
import '../state/app_controller.dart';
import '../theme/kems_theme.dart';
import '../widgets/kems_ui.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final mapping = controller.mapping;
    final advice = controller.entity(mapping.advice)?.state ??
        'KEMS is observing your energy use';
    final phase = controller.entity(mapping.phase)?.state ?? 'Observe';
    final cheap = controller.isOn(mapping.cheapPeriodConfirmed);
    final liveEntities = controller.kemsEntities.where(_isLiveEntity).toList();

    return KemsPage(
      onRefresh: controller.refresh,
      children: [
        Row(
          children: [
            LivePill(connected: controller.connected),
            const Spacer(),
            Text(
              'Updated ${_updated()}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 14),
        KemsCard(
          glow: cheap ? KemsTheme.cyan : KemsTheme.green,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KemsTheme.green.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: KemsTheme.green,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cheap ? 'Cheap period active' : 'KEMS is $phase',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      advice,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        KemsCard(
          glow: KemsTheme.green,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: KemsTheme.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Live data is measured by Home Assistant from your configured Octopus, Ohme, meter, battery and solar entities. System profile: ${displayEntity(controller, mapping.systemProfile)}. Battery data: ${controller.isOn(mapping.batteryDataAvailable) ? 'available' : 'not yet available'}.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Live energy now'),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.35,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricTile(
              label: 'Grid',
              value: displayEntity(controller, mapping.gridNetPower),
              caption: controller.entity(mapping.gridFlowDirection)?.state ??
                  'Live flow',
              icon: Icons.electric_meter_outlined,
              color: KemsTheme.blue,
            ),
            MetricTile(
              label: 'Home',
              value: displayEntity(controller, mapping.houseLoad),
              caption: 'Current demand',
              icon: Icons.home_outlined,
              color: KemsTheme.purple,
            ),
            MetricTile(
              label: 'Battery',
              value: displayEntity(controller, mapping.batterySoc),
              caption: displayEntity(controller, mapping.batteryPower),
              icon: Icons.battery_charging_full,
              color: KemsTheme.green,
            ),
            MetricTile(
              label: 'EV (Ohme)',
              value: displayEntity(controller, mapping.evSoc),
              caption: displayEntity(controller, mapping.evPower),
              icon: Icons.electric_car_outlined,
              color: KemsTheme.cyan,
            ),
            MetricTile(
              label: 'Tariff',
              value: displayEntity(controller, mapping.currentRate, decimals: 3),
              caption: cheap ? 'Cheap rate' : 'Standard rate',
              icon: Icons.bolt,
              color: cheap ? KemsTheme.green : KemsTheme.amber,
            ),
            MetricTile(
              label: 'Grid import',
              value: displayEntity(controller, mapping.gridImport),
              caption: 'Measured now',
              icon: Icons.download_rounded,
              color: KemsTheme.blue,
            ),
          ],
        ),
        const SectionTitle('Observed today'),
        KemsCard(
          child: Row(
            children: [
              _summary(
                'Cost',
                displayEntity(controller, mapping.observedCostToday, decimals: 2),
              ),
              _divider(),
              _summary(
                'Export income',
                displayEntity(
                  controller,
                  mapping.observedExportIncomeToday,
                  decimals: 2,
                ),
                color: KemsTheme.green,
              ),
              _divider(),
              _summary(
                'Imported',
                displayEntity(controller, mapping.observedGridImportToday),
              ),
            ],
          ),
        ),
        const SectionTitle('KEMS recommendation'),
        KemsCard(
          glow: KemsTheme.green,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: KemsTheme.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  advice,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        SectionTitle(
          'All live KEMS data',
          trailing: Text(
            '${liveEntities.length}',
            style: const TextStyle(color: KemsTheme.green),
          ),
        ),
        EntityDirectory(entities: liveEntities, accent: KemsTheme.green),
      ],
    );
  }

  bool _isLiveEntity(HaEntity entity) {
    final id = entity.entityId;
    return !id.contains('simulat') &&
        !id.contains('predicted_') &&
        !id.contains('proposal_') &&
        !id.contains('roi_') &&
        !id.contains('payback') &&
        !id.contains('system_investment') &&
        !id.contains('typical_') &&
        !id.contains('lifetime_simulated');
  }

  Widget _summary(String label, String value, {Color color = Colors.white}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: Colors.white10);

  String _updated() {
    final date = controller.lastUpdated;
    if (date == null) {
      return '—';
    }
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
