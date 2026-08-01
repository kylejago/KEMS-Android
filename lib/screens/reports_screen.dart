import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../theme/kems_theme.dart';
import '../widgets/kems_ui.dart';
import '../widgets/metric_card.dart';

enum ReportMode { live, simulation }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportMode mode = ReportMode.live;
  bool loading = true;
  List<FlSpot> spots = const [];
  String? error;

  String _value(String id, {String fallback = '—'}) {
    final entity = widget.controller.entity(id);
    if (entity == null || ['unknown', 'unavailable'].contains(entity.state)) {
      return fallback;
    }
    return '${entity.state}${entity.unit.isEmpty ? '' : ' ${entity.unit}'}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
      spots = const [];
    });
    try {
      final mapping = widget.controller.mapping;
      final entityId = mode == ReportMode.live
          ? mapping.houseLoad
          : mapping.simulatedHouseLoadPower;
      final rows = await widget.controller.api?.getHistory(entityId) ?? const [];
      final parsed = <FlSpot>[];
      for (var i = 0; i < rows.length; i++) {
        final value = double.tryParse(rows[i]['state']?.toString() ?? '');
        if (value != null && value.isFinite) {
          parsed.add(FlSpot(i.toDouble(), value));
        }
      }
      if (mounted) {
        setState(() => spots = parsed);
      }
    } catch (exception) {
      if (mounted) {
        setState(() => error = '$exception');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapping = widget.controller.mapping;
    final simulated = mode == ReportMode.simulation;
    final values = spots.map((spot) => spot.y).toList();
    final minimum = values.isEmpty ? 0.0 : values.reduce(math.min);
    final maximum = values.isEmpty ? 1.0 : values.reduce(math.max);
    final padding = math.max((maximum - minimum) * .12, .1);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Reports', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        SegmentedButton<ReportMode>(
          segments: const [
            ButtonSegment(
              value: ReportMode.live,
              icon: Icon(Icons.sensors),
              label: Text('Live'),
            ),
            ButtonSegment(
              value: ReportMode.simulation,
              icon: Icon(Icons.science),
              label: Text('Simulation'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) {
            setState(() => mode = selection.first);
            _load();
          },
        ),
        const SizedBox(height: 14),
        KemsCard(
          glow: simulated ? KemsTheme.purple : KemsTheme.green,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                simulated ? Icons.science_outlined : Icons.sensors_outlined,
                color: simulated ? KemsTheme.purple : KemsTheme.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  simulated
                      ? 'Simulation reports compare the proposed KEMS system profile, tariff strategy, battery and solar model against observed demand.'
                      : 'Live reports use measured Home Assistant data from your configured meters, tariff, EV and any installed battery or solar equipment.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 4 : 2,
          childAspectRatio: 1.15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: simulated
              ? [
                  MetricCard(title: 'Simulated cost', value: _value(mapping.simulatedCostToday), icon: Icons.payments),
                  MetricCard(title: 'Simulated saving', value: _value(mapping.simulatedSavingToday), icon: Icons.savings),
                  MetricCard(title: 'Grid import', value: _value(mapping.simulatedGridImportToday), icon: Icons.download),
                  MetricCard(title: 'Grid export', value: _value(mapping.simulatedGridExportToday), icon: Icons.upload),
                  MetricCard(title: 'Solar generated', value: _value(mapping.simulatedSolarGenerationToday), icon: Icons.solar_power),
                  MetricCard(title: 'Annual saving', value: _value(mapping.predictedAnnualSaving), icon: Icons.trending_up),
                  MetricCard(title: 'Payback', value: _value(mapping.predictedPayback), subtitle: _value(mapping.predictedPaybackDate), icon: Icons.calendar_month),
                  MetricCard(title: 'System profile', value: _value(mapping.systemProfile), icon: Icons.settings_suggest),
                ]
              : [
                  MetricCard(title: 'Whole-home cost', value: _value(mapping.wholeHomeCostToday), icon: Icons.payments),
                  MetricCard(title: 'Whole-home energy', value: _value(mapping.wholeHomeEnergyToday), icon: Icons.energy_savings_leaf),
                  MetricCard(title: 'Grid import', value: _value(mapping.observedGridImportToday), icon: Icons.download),
                  MetricCard(title: 'Grid export', value: _value(mapping.observedGridExportToday), icon: Icons.upload),
                  MetricCard(title: 'Export income', value: _value(mapping.observedExportIncomeToday), icon: Icons.currency_pound),
                  MetricCard(title: 'Gas today', value: _value(mapping.gasUsageToday), subtitle: _value(mapping.gasCostToday), icon: Icons.local_fire_department),
                  MetricCard(title: 'Data quality', value: _value(mapping.dataQuality), icon: Icons.fact_check),
                  MetricCard(title: 'Learning confidence', value: _value(mapping.learningConfidence), icon: Icons.psychology),
                ],
        ),
        const SizedBox(height: 18),
        Text(
          simulated
              ? 'Simulated house load — last 24 hours'
              : 'Measured house load — last 24 hours',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 360,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 24, 18, 14),
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(child: Text(error!))
                      : spots.length < 2
                          ? const Center(child: Text('KEMS is still collecting history.'))
                          : LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: math.max(spots.length - 1, 1).toDouble(),
                                minY: minimum - padding,
                                maxY: maximum + padding,
                                clipData: const FlClipData.all(),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.white12),
                                ),
                                gridData: const FlGridData(show: true),
                                titlesData: const FlTitlesData(
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 18)),
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 46)),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    preventCurveOverShooting: true,
                                    dotData: const FlDotData(show: false),
                                    barWidth: 3,
                                    color: simulated ? KemsTheme.purple : KemsTheme.green,
                                  ),
                                ],
                              ),
                            ),
            ),
          ),
        ),
      ],
    );
  }
}
