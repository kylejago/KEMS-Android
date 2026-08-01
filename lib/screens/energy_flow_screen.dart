import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../models/ha_entity.dart';
import '../state/app_controller.dart';
import '../theme/kems_theme.dart';
import '../widgets/kems_ui.dart';

enum FlowDataMode { live, simulation }

class EnergyFlowScreen extends StatefulWidget {
  const EnergyFlowScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<EnergyFlowScreen> createState() => _EnergyFlowScreenState();
}

class _EnergyFlowScreenState extends State<EnergyFlowScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation;
  FlowDataMode mode = FlowDataMode.live;

  double _solar = 0;
  double _battery = 0;
  double _gridImport = 0;
  double _gridExport = 0;
  double _home = 0;
  double _ev = 0;
  bool _smoothingReady = false;

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )
      ..addListener(_smoothValues)
      ..repeat();
  }

  @override
  void dispose() {
    animation
      ..removeListener(_smoothValues)
      ..dispose();
    super.dispose();
  }

  void _smoothValues() {
    final targets = _targetValues();
    if (!_smoothingReady) {
      _solar = targets.solar;
      _battery = targets.battery;
      _gridImport = targets.gridImport;
      _gridExport = targets.gridExport;
      _home = targets.home;
      _ev = targets.ev;
      _smoothingReady = true;
      return;
    }

    const factor = .055;
    _solar += (targets.solar - _solar) * factor;
    _battery += (targets.battery - _battery) * factor;
    _gridImport += (targets.gridImport - _gridImport) * factor;
    _gridExport += (targets.gridExport - _gridExport) * factor;
    _home += (targets.home - _home) * factor;
    _ev += (targets.ev - _ev) * factor;
  }

  _FlowValues _targetValues() {
    final mapping = widget.controller.mapping;
    final simulated = mode == FlowDataMode.simulation;
    return _FlowValues(
      solar: _numeric(
        simulated ? mapping.simulatedSolarPower : mapping.solarPower,
      ),
      battery: _numeric(
        simulated ? mapping.simulatedBatteryPower : mapping.batteryPower,
      ),
      gridImport: _numeric(
        simulated ? mapping.simulatedGridImportPower : mapping.gridImport,
      ),
      gridExport: _numeric(
        simulated ? mapping.simulatedGridExportPower : mapping.gridExport,
      ),
      home: _numeric(
        simulated ? mapping.simulatedHouseLoadPower : mapping.houseLoad,
      ),
      ev: simulated ? 0 : _numeric(mapping.evPower),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final mapping = controller.mapping;
    final simulated = mode == FlowDataMode.simulation;

    final solarId = simulated ? mapping.simulatedSolarPower : mapping.solarPower;
    final batteryPowerId =
        simulated ? mapping.simulatedBatteryPower : mapping.batteryPower;
    final batterySocId =
        simulated ? mapping.simulatedBatterySoc : mapping.batterySoc;
    final gridImportId =
        simulated ? mapping.simulatedGridImportPower : mapping.gridImport;
    final gridExportId =
        simulated ? mapping.simulatedGridExportPower : mapping.gridExport;
    final homeId =
        simulated ? mapping.simulatedHouseLoadPower : mapping.houseLoad;

    final flows = _buildFlows(
      solar: _solar,
      battery: _battery,
      gridImport: _gridImport,
      gridExport: _gridExport,
      ev: _ev,
    );

    final batteryDischarge = math.max(-_battery, 0);
    final batteryCharge = math.max(_battery, 0);
    final inputs = _solar + _gridImport + batteryDischarge;
    final uses = _home + _gridExport + batteryCharge;
    final difference = inputs - uses;
    final balanced = difference.abs() <= math.max(.15, inputs.abs() * .08);
    final advice = controller.entity(mapping.advice)?.state;

    return KemsPage(
      onRefresh: controller.refresh,
      children: [
        const SectionTitle('Energy flow'),
        SegmentedButton<FlowDataMode>(
          segments: const [
            ButtonSegment(
              value: FlowDataMode.live,
              icon: Icon(Icons.sensors),
              label: Text('Live'),
            ),
            ButtonSegment(
              value: FlowDataMode.simulation,
              icon: Icon(Icons.science),
              label: Text('Simulation'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) {
            setState(() {
              mode = selection.first;
              _smoothingReady = false;
            });
          },
        ),
        const SizedBox(height: 14),
        _DecisionRibbon(
          text: _decisionText(advice, simulated),
          simulated: simulated,
        ),
        const SizedBox(height: 12),
        KemsCard(
          padding: const EdgeInsets.all(8),
          glow: simulated ? KemsTheme.purple : KemsTheme.green,
          child: SizedBox(
            height: 540,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _EnergyFlowPainter(
                              progress: animation.value,
                              flows: flows,
                            ),
                          ),
                        ),
                        _positionedNode(
                          size,
                          const Offset(.50, .13),
                          icon: Icons.wb_sunny_rounded,
                          label: 'Solar',
                          value: _displayPower(_solar, solarId),
                          age: _ageFor(solarId),
                          color: KemsTheme.amber,
                          active: _solar.abs() > .01,
                          onTap: () => _showNodeDetails(
                            title: 'Solar',
                            icon: Icons.wb_sunny_rounded,
                            color: KemsTheme.amber,
                            description: simulated
                                ? 'Modelled solar generation from the configured KEMS system profile and forecast assumptions.'
                                : 'Measured solar generation supplied by the configured Home Assistant source entity.',
                            entityIds: [solarId, mapping.systemProfile],
                          ),
                        ),
                        _positionedNode(
                          size,
                          const Offset(.15, .50),
                          icon: Icons.electric_meter_rounded,
                          label: 'Grid',
                          value: _gridImport > _gridExport
                              ? '${_format(_gridImport)} import'
                              : '${_format(_gridExport)} export',
                          age: _newestAge([gridImportId, gridExportId]),
                          color: KemsTheme.blue,
                          active: _gridImport.abs() + _gridExport.abs() > .01,
                          onTap: () => _showNodeDetails(
                            title: 'Grid',
                            icon: Icons.electric_meter_rounded,
                            color: KemsTheme.blue,
                            description: simulated
                                ? 'Modelled grid exchange after applying the simulated solar, battery and tariff strategy.'
                                : 'Live import and export reported through the KEMS Home Assistant integration.',
                            entityIds: [
                              gridImportId,
                              gridExportId,
                              simulated
                                  ? mapping.simulatedGridNetPower
                                  : mapping.gridNetPower,
                              mapping.currentRate,
                              mapping.cheapPeriodConfirmed,
                            ],
                          ),
                        ),
                        _positionedNode(
                          size,
                          const Offset(.50, .50),
                          icon: Icons.home_rounded,
                          label: 'Home',
                          value: _displayPower(_home, homeId),
                          age: _ageFor(homeId),
                          color: KemsTheme.purple,
                          active: _home.abs() > .01,
                          featured: true,
                          onTap: () => _showNodeDetails(
                            title: 'Home',
                            icon: Icons.home_rounded,
                            color: KemsTheme.purple,
                            description: simulated
                                ? 'The modelled home load used by KEMS when testing the proposed energy system.'
                                : 'The current measured home demand. Home is the central balance point for every flow.',
                            entityIds: [
                              homeId,
                              mapping.dataQuality,
                              mapping.learningConfidence,
                              mapping.advice,
                            ],
                          ),
                        ),
                        _positionedNode(
                          size,
                          const Offset(.85, .50),
                          icon: Icons.battery_charging_full_rounded,
                          label: 'Battery',
                          value:
                              '${displayEntity(controller, batterySocId)}\n${_displayPower(_battery, batteryPowerId)}',
                          age: _newestAge([batteryPowerId, batterySocId]),
                          color: KemsTheme.green,
                          active: _battery.abs() > .01,
                          onTap: () => _showNodeDetails(
                            title: 'Battery',
                            icon: Icons.battery_charging_full_rounded,
                            color: KemsTheme.green,
                            description: simulated
                                ? 'Modelled battery state, charging and discharge behaviour using the configured system specification.'
                                : 'Live battery state and power. Positive power is treated as charging and negative power as discharging.',
                            entityIds: [
                              batterySocId,
                              batteryPowerId,
                              mapping.systemProfile,
                              mapping.predictedEnergyUntilOffPeak,
                            ],
                          ),
                        ),
                        _positionedNode(
                          size,
                          const Offset(.50, .86),
                          icon: Icons.electric_car_rounded,
                          label: 'EV',
                          value: simulated
                              ? 'Included in load'
                              : _displayPower(_ev, mapping.evPower),
                          age: simulated ? 'Modelled' : _ageFor(mapping.evPower),
                          color: KemsTheme.cyan,
                          active: _ev.abs() > .01,
                          onTap: () => _showNodeDetails(
                            title: 'EV',
                            icon: Icons.electric_car_rounded,
                            color: KemsTheme.cyan,
                            description: simulated
                                ? 'EV demand is included in the modelled home load until a dedicated simulated EV stream is exposed.'
                                : 'Live Ohme charging state, charging power and vehicle state of charge exposed through KEMS.',
                            entityIds: simulated
                                ? [homeId, mapping.systemProfile]
                                : [
                                    mapping.evPower,
                                    mapping.evSoc,
                                    mapping.evConnected,
                                    mapping.evCharging,
                                    mapping.intelligentSlot,
                                  ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        _BalancePanel(
          inputs: inputs,
          uses: uses,
          difference: difference,
          balanced: balanced,
          simulated: simulated,
        ),
        const SizedBox(height: 14),
        KemsCard(
          child: Row(
            children: [
              Icon(
                simulated ? Icons.science_outlined : Icons.sensors_outlined,
                color: simulated ? KemsTheme.purple : KemsTheme.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  simulated
                      ? 'Values are smoothed for display. Tap any node to see the model inputs, system profile and underlying KEMS entities.'
                      : 'Live readings glide between Home Assistant updates. Tap any node for source details, data age and the current KEMS context.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _numeric(String id) {
    return widget.controller.entity(id)?.numericState ?? 0;
  }

  String _displayPower(double smoothed, String entityId) {
    final entity = widget.controller.entity(entityId);
    if (entity == null || entity.state == 'unknown' || entity.state == 'unavailable') {
      return 'Unavailable';
    }
    final unit = entity.unit.isEmpty ? 'kW' : entity.unit;
    return '${smoothed.abs().toStringAsFixed(2)} $unit';
  }

  String _ageFor(String id) {
    final changed = widget.controller.entity(id)?.lastChanged;
    if (changed == null) {
      return 'No timestamp';
    }
    final difference = DateTime.now().difference(changed.toLocal());
    if (difference.isNegative || difference.inSeconds < 5) {
      return 'Live • just now';
    }
    if (difference.inSeconds < 60) {
      return 'Live • ${difference.inSeconds}s ago';
    }
    if (difference.inMinutes < 5) {
      return 'Live • ${difference.inMinutes}m ago';
    }
    return 'Delayed • ${difference.inMinutes}m ago';
  }

  String _newestAge(List<String> ids) {
    DateTime? newest;
    for (final id in ids) {
      final changed = widget.controller.entity(id)?.lastChanged;
      if (changed != null && (newest == null || changed.isAfter(newest))) {
        newest = changed;
      }
    }
    if (newest == null) {
      return 'No timestamp';
    }
    final difference = DateTime.now().difference(newest.toLocal());
    if (difference.isNegative || difference.inSeconds < 5) {
      return 'Live • just now';
    }
    if (difference.inSeconds < 60) {
      return 'Live • ${difference.inSeconds}s ago';
    }
    if (difference.inMinutes < 5) {
      return 'Live • ${difference.inMinutes}m ago';
    }
    return 'Delayed • ${difference.inMinutes}m ago';
  }

  String _decisionText(String? advice, bool simulated) {
    final clean = advice?.trim();
    if (clean != null &&
        clean.isNotEmpty &&
        clean != 'unknown' &&
        clean != 'unavailable') {
      return clean;
    }
    if (simulated) {
      return 'KEMS is modelling how the proposed system would supply the home.';
    }
    if (_gridImport > .05) {
      return 'The home is currently importing energy from the grid.';
    }
    if (_gridExport > .05) {
      return 'The home is currently exporting energy to the grid.';
    }
    if (_battery < -.05) {
      return 'The battery is currently helping to supply the home.';
    }
    return 'KEMS is observing the live energy system.';
  }

  List<_Flow> _buildFlows({
    required double solar,
    required double battery,
    required double gridImport,
    required double gridExport,
    required double ev,
  }) {
    return [
      _Flow(
        from: const Offset(.50, .22),
        to: const Offset(.50, .39),
        color: KemsTheme.amber,
        power: solar.abs(),
        active: solar.abs() > .01,
      ),
      _Flow(
        from: const Offset(.25, .50),
        to: const Offset(.39, .50),
        color: KemsTheme.blue,
        power: math.max(gridImport, gridExport).abs(),
        active: gridImport.abs() + gridExport.abs() > .01,
        reverse: gridExport > gridImport,
      ),
      _Flow(
        from: const Offset(.61, .50),
        to: const Offset(.75, .50),
        color: KemsTheme.green,
        power: battery.abs(),
        active: battery.abs() > .01,
        reverse: battery < 0,
      ),
      _Flow(
        from: const Offset(.50, .61),
        to: const Offset(.50, .77),
        color: KemsTheme.cyan,
        power: ev.abs(),
        active: ev.abs() > .01,
      ),
    ];
  }

  Widget _positionedNode(
    Size size,
    Offset point, {
    required IconData icon,
    required String label,
    required String value,
    required String age,
    required Color color,
    required bool active,
    required VoidCallback onTap,
    bool featured = false,
  }) {
    final width = featured ? 142.0 : 124.0;
    final height = featured ? 116.0 : 100.0;
    return Positioned(
      left: size.width * point.dx - width / 2,
      top: size.height * point.dy - height / 2,
      width: width,
      height: height,
      child: _FlowNode(
        icon: icon,
        label: label,
        value: value,
        age: age,
        color: color,
        active: active,
        featured: featured,
        onTap: onTap,
      ),
    );
  }

  Future<void> _showNodeDetails({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required List<String> entityIds,
  }) async {
    final entities = <HaEntity>[];
    for (final id in entityIds) {
      final entity = widget.controller.entity(id);
      if (entity != null) {
        entities.add(entity);
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF071116),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(icon, color: color, size: 30),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, height: 1.45),
                ),
                const SizedBox(height: 18),
                if (entities.isEmpty)
                  const Text(
                    'No matching KEMS entities are currently available.',
                    style: TextStyle(color: Colors.white54),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: entities.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entity = entities[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(entity.friendlyName),
                          subtitle: Text(
                            '${entity.entityId}\n${_ageFor(entity.entityId)}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            entity.unit.isEmpty
                                ? entity.state
                                : '${entity.state} ${entity.unit}',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _format(double value) {
    if (value.abs() < .005) {
      return '0 kW';
    }
    return '${value.abs().toStringAsFixed(2)} kW';
  }
}

class _DecisionRibbon extends StatelessWidget {
  const _DecisionRibbon({required this.text, required this.simulated});

  final String text;
  final bool simulated;

  @override
  Widget build(BuildContext context) {
    final color = simulated ? KemsTheme.purple : KemsTheme.green;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        border: Border.all(color: color.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({
    required this.inputs,
    required this.uses,
    required this.difference,
    required this.balanced,
    required this.simulated,
  });

  final double inputs;
  final double uses;
  final double difference;
  final bool balanced;
  final bool simulated;

  @override
  Widget build(BuildContext context) {
    final color = balanced ? KemsTheme.green : KemsTheme.amber;
    return KemsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                balanced ? Icons.balance_rounded : Icons.sync_problem_rounded,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  balanced ? 'Flow balance looks healthy' : 'Flow timing differs',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${difference >= 0 ? '+' : ''}${difference.toStringAsFixed(2)} kW',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _BalanceValue(label: 'Inputs', value: inputs)),
              const SizedBox(width: 12),
              Expanded(child: _BalanceValue(label: 'Uses', value: uses)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            simulated
                ? 'The comparison checks the modelled sources against modelled home use, export and battery charging.'
                : 'A small difference is normal because source sensors can update at different times. Larger differences can reveal delayed or missing data.',
            style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _BalanceValue extends StatelessWidget {
  const _BalanceValue({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(2)} kW',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _FlowNode extends StatelessWidget {
  const _FlowNode({
    required this.icon,
    required this.label,
    required this.value,
    required this.age,
    required this.color,
    required this.active,
    required this.onTap,
    this.featured = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String age;
  final Color color;
  final bool active;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final delayed = age.startsWith('Delayed');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(featured ? 24 : 17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          padding: EdgeInsets.all(featured ? 11 : 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: active ? .14 : .055),
            border: Border.all(
              color: color.withValues(alpha: active ? .80 : .25),
              width: featured ? 2 : (active ? 1.5 : 1),
            ),
            borderRadius: BorderRadius.circular(featured ? 24 : 17),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: featured ? .22 : .16),
                      blurRadius: featured ? 30 : 22,
                      spreadRadius: featured ? 2 : 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? color : color.withValues(alpha: .55),
                size: featured ? 27 : 21,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: featured ? 14 : 12,
                ),
              ),
              Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: featured ? 11 : 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                age,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: delayed ? KemsTheme.amber : Colors.white38,
                  fontSize: featured ? 9 : 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowValues {
  const _FlowValues({
    required this.solar,
    required this.battery,
    required this.gridImport,
    required this.gridExport,
    required this.home,
    required this.ev,
  });

  final double solar;
  final double battery;
  final double gridImport;
  final double gridExport;
  final double home;
  final double ev;
}

class _Flow {
  const _Flow({
    required this.from,
    required this.to,
    required this.color,
    required this.power,
    required this.active,
    this.reverse = false,
  });

  final Offset from;
  final Offset to;
  final Color color;
  final double power;
  final bool active;
  final bool reverse;
}

class _EnergyFlowPainter extends CustomPainter {
  const _EnergyFlowPainter({required this.progress, required this.flows});

  final double progress;
  final List<_Flow> flows;

  @override
  void paint(Canvas canvas, Size size) {
    for (final flow in flows) {
      final start = Offset(flow.from.dx * size.width, flow.from.dy * size.height);
      final end = Offset(flow.to.dx * size.width, flow.to.dy * size.height);
      final path = _path(start, end);
      final basePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = flow.active ? 4 : 2
        ..color = flow.color.withValues(alpha: flow.active ? .20 : .07);
      canvas.drawPath(path, basePaint);

      if (!flow.active) {
        continue;
      }

      final metric = path.computeMetrics().first;
      final cycles = _cyclesForPower(flow.power);
      var head = (progress * cycles) % 1;
      if (flow.reverse) {
        head = 1 - head;
      }

      for (var band = 0; band < 4; band++) {
        final offset = band * .20;
        var centre = flow.reverse ? head + offset : head - offset;
        centre %= 1;
        if (centre < 0) {
          centre += 1;
        }
        _drawWaveBand(canvas, metric, centre, flow.color, band, flow.power);
      }
    }
  }

  int _cyclesForPower(double power) {
    if (power >= 7) {
      return 4;
    }
    if (power >= 3) {
      return 3;
    }
    if (power >= .75) {
      return 2;
    }
    return 1;
  }

  void _drawWaveBand(
    Canvas canvas,
    PathMetric metric,
    double centre,
    Color color,
    int band,
    double power,
  ) {
    const span = .16;
    final intensity = .55 + math.min(power.abs(), 10) / 10 * .35;
    final start = centre - span / 2;
    final end = centre + span / 2;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12 - band * 1.5
      ..color = color.withValues(alpha: (.075 - band * .012) * intensity);
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.8 - band * .42
      ..color = color.withValues(alpha: (.88 - band * .15) * intensity);

    void drawRange(double a, double b) {
      final segment = metric.extractPath(metric.length * a, metric.length * b);
      canvas.drawPath(segment, glow);
      canvas.drawPath(segment, core);
    }

    if (start < 0) {
      drawRange(0, end);
      drawRange(1 + start, 1);
    } else if (end > 1) {
      drawRange(start, 1);
      drawRange(0, end - 1);
    } else {
      drawRange(start, end);
    }
  }

  Path _path(Offset start, Offset end) {
    if ((start.dx - end.dx).abs() < 2 || (start.dy - end.dy).abs() < 2) {
      return Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(end.dx, end.dy);
    }
    final middleX = (start.dx + end.dx) / 2;
    return Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(middleX, start.dy, middleX, end.dy, end.dx, end.dy);
  }

  @override
  bool shouldRepaint(covariant _EnergyFlowPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.flows != flows;
  }
}
