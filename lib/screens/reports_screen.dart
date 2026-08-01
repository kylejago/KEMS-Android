import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../widgets/metric_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool loading = true;
  List<FlSpot> spots = const [];
  String? error;

  String _value(String id, {String fallback = '—'}) {
    final e = widget.controller.entity(id);
    if (e == null || ['unknown', 'unavailable'].contains(e.state)) {
      return fallback;
    }
    return '${e.state}${e.unit.isEmpty ? '' : ' ${e.unit}'}';
  }

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final rows = await widget.controller.api?.getHistory(widget.controller.mapping.houseLoad) ?? const [];
      final parsed = <FlSpot>[];
      for (var i = 0; i < rows.length; i++) {
        final value = double.tryParse(rows[i]['state']?.toString() ?? '');
        if (value != null) {
          parsed.add(FlSpot(i.toDouble(), value));
        }
      }
      if (mounted) {
        setState(() => spots = parsed);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.controller.mapping;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Reports', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 4 : 2,
        childAspectRatio: 1.15,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          MetricCard(title: 'Whole-home cost', value: _value(m.wholeHomeCostToday), icon: Icons.payments),
          MetricCard(title: 'Whole-home energy', value: _value(m.wholeHomeEnergyToday), icon: Icons.energy_savings_leaf),
          MetricCard(title: 'Gas today', value: _value(m.gasUsageToday), subtitle: _value(m.gasCostToday), icon: Icons.local_fire_department),
          MetricCard(title: 'Simulated saving', value: _value(m.simulatedSavingToday), icon: Icons.savings),
          MetricCard(title: 'System investment', value: _value(m.systemInvestment), icon: Icons.account_balance),
          MetricCard(title: 'Annual saving', value: _value(m.predictedAnnualSaving), icon: Icons.trending_up),
          MetricCard(title: 'Payback', value: _value(m.predictedPayback), subtitle: _value(m.predictedPaybackDate), icon: Icons.calendar_month),
          MetricCard(title: 'ROI confidence', value: _value(m.roiConfidence), subtitle: _value(m.roiStatus), icon: Icons.query_stats),
        ],
      ),
      const SizedBox(height: 16),
      Text('House load — last 24 hours', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      SizedBox(height: 280, child: Card(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 20, 12),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text(error!))
                : spots.length < 2
                    ? const Center(child: Text('KEMS is still collecting history.'))
                    : LineChart(LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineBarsData: [LineChartBarData(spots: spots, isCurved: true, dotData: const FlDotData(show: false))],
                      )),
      ))),
    ]);
  }
}
