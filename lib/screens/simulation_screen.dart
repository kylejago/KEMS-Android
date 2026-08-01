import 'package:flutter/material.dart';

import '../models/ha_entity.dart';
import '../state/app_controller.dart';
import '../theme/kems_theme.dart';
import '../widgets/kems_ui.dart';

class SimulationScreen extends StatelessWidget {
  const SimulationScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final m = controller.mapping;
    final ready = controller.isOn(m.simulationReady);
    final saving = controller.isOn(m.simulationSaving);
    final simulatedEntities = controller.kemsEntities.where(_isSimulationEntity).toList();

    return KemsPage(
      onRefresh: controller.refresh,
      children: [
        Row(
          children: [
            _ModePill(
              label: ready ? 'Simulation ready' : 'Simulation learning',
              icon: Icons.science_outlined,
              color: ready ? KemsTheme.purple : KemsTheme.amber,
            ),
            const Spacer(),
            Text(
              '${simulatedEntities.length} simulation outputs',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 14),
        KemsCard(
          glow: saving ? KemsTheme.green : KemsTheme.purple,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: KemsTheme.purple.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: KemsTheme.purple,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KEMS simulated system',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      saving
                          ? 'The current simulation shows a saving against observed use.'
                          : 'KEMS is modelling the battery, solar, grid and tariff strategy.',
                      style: const TextStyle(color: Colors.white60, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        KemsCard(
          glow: KemsTheme.purple,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.tune_rounded, color: KemsTheme.purple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This model simulates the proposed KEMS system using your observed demand, tariff windows and the configured system profile: ${displayEntity(controller, m.systemProfile)}. Investment model: ${displayEntity(controller, m.systemInvestment)}. Installed system: ${controller.isOn(m.systemInstalled) ? 'yes' : 'proposal mode'}.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Simulated power now'),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.35,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricTile(
              label: 'Grid import',
              value: displayEntity(controller, m.simulatedGridImportPower),
              caption: 'Modelled now',
              icon: Icons.download_rounded,
              color: KemsTheme.blue,
            ),
            MetricTile(
              label: 'Grid export',
              value: displayEntity(controller, m.simulatedGridExportPower),
              caption: 'Modelled now',
              icon: Icons.upload_rounded,
              color: KemsTheme.cyan,
            ),
            MetricTile(
              label: 'Battery',
              value: displayEntity(controller, m.simulatedBatterySoc),
              caption: displayEntity(controller, m.simulatedBatteryPower),
              icon: Icons.battery_charging_full_rounded,
              color: KemsTheme.green,
            ),
            MetricTile(
              label: 'Solar',
              value: displayEntity(controller, m.simulatedSolarPower),
              caption: 'Modelled generation',
              icon: Icons.wb_sunny_outlined,
              color: KemsTheme.amber,
            ),
          ],
        ),
        const SectionTitle('Simulation today'),
        KemsCard(
          child: Column(
            children: [
              _summaryRow(
                'Simulated KEMS cost',
                displayEntity(controller, m.simulatedCostToday, decimals: 2),
                Icons.payments_outlined,
                KemsTheme.purple,
              ),
              const Divider(height: 24),
              _summaryRow(
                'Predicted saving',
                displayEntity(controller, m.simulatedSavingToday, decimals: 2),
                Icons.savings_outlined,
                KemsTheme.green,
              ),
              const Divider(height: 24),
              _summaryRow(
                'Avoided day-rate import',
                displayEntity(controller, m.avoidedDayRateImportToday),
                Icons.shield_outlined,
                KemsTheme.cyan,
              ),
              const Divider(height: 24),
              _summaryRow(
                'Simulated solar generated',
                displayEntity(controller, m.simulatedSolarGenerationToday),
                Icons.solar_power_outlined,
                KemsTheme.amber,
              ),
            ],
          ),
        ),
        SectionTitle(
          'All simulation data',
          trailing: Text(
            '${simulatedEntities.length}',
            style: const TextStyle(color: KemsTheme.purple),
          ),
        ),
        EntityDirectory(entities: simulatedEntities, accent: KemsTheme.purple),
      ],
    );
  }

  bool _isSimulationEntity(HaEntity entity) {
    final id = entity.entityId;
    return id.contains('simulat') ||
        id.contains('predicted_') ||
        id.contains('proposal_') ||
        id.contains('roi_') ||
        id.contains('payback') ||
        id.contains('system_investment') ||
        id.contains('system_profile') ||
        id.contains('typical_') ||
        id.contains('lifetime_simulated');
  }

  Widget _summaryRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
