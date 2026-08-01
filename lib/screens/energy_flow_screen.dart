import 'dart:math' as math;

import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..repeat();
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
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
    final homeId = simulated ? mapping.simulatedHouseLoadPower : mapping.houseLoad;

    final solar = _numeric(solarId);
    final battery = _numeric(batteryPowerId);
    final gridImport = _numeric(gridImportId);
    final gridExport = _numeric(gridExportId);
    final home = _numeric(homeId);
    final ev = simulated ? 0.0 : _numeric(mapping.evPower);

    final flows = _buildFlows(
      solar: solar,
      battery: battery,
      gridImport: gridImport,
      gridExport: gridExport,
      home: home,
      ev: ev,
    );

    return KemsPage(
      onRefresh: controller.refresh,
      children: [
        const SectionTitle('Moving energy flow'),
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
            setState(() => mode = selection.first);
          },
        ),
        const SizedBox(height: 14),
        KemsCard(
          padding: const EdgeInsets.all(8),
          glow: simulated ? KemsTheme.purple : KemsTheme.green,
          child: SizedBox(
            height: 520,
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
                          const Offset(.50, .10),
                          icon: Icons.wb_sunny_rounded,
                          label: 'Solar',
                          value: displayEntity(controller, solarId),
                          color: KemsTheme.amber,
                          active: solar.abs() > .01,
                        ),
                        _positionedNode(
                          size,
                          const Offset(.13, .48),
                          icon: Icons.electric_meter_rounded,
                          label: 'Grid',
                          value: gridImport > gridExport
                              ? '${_format(gridImport)} import'
                              : '${_format(gridExport)} export',
                          color: KemsTheme.blue,
                          active: gridImport.abs() + gridExport.abs() > .01,
                        ),
                        _positionedNode(
                          size,
                          const Offset(.87, .48),
                          icon: Icons.home_rounded,
                          label: 'Home',
                          value: displayEntity(controller, homeId),
                          color: KemsTheme.purple,
                          active: home.abs() > .01,
                        ),
                        _positionedNode(
                          size,
                          const Offset(.50, .66),
                          icon: Icons.battery_charging_full_rounded,
                          label: 'Battery',
                          value:
                              '${displayEntity(controller, batterySocId)}\n${displayEntity(controller, batteryPowerId)}',
                          color: KemsTheme.green,
                          active: battery.abs() > .01,
                        ),
                        _positionedNode(
                          size,
                          const Offset(.50, .90),
                          icon: Icons.electric_car_rounded,
                          label: 'EV',
                          value: simulated
                              ? 'Included in load'
                              : displayEntity(controller, mapping.evPower),
                          color: KemsTheme.cyan,
                          active: ev.abs() > .01,
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
                      ? 'Particles show the direction of KEMS modelled power. Inactive paths remain dim.'
                      : 'Particles move in the measured direction of energy. Their speed increases with power.',
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

  List<_Flow> _buildFlows({
    required double solar,
    required double battery,
    required double gridImport,
    required double gridExport,
    required double home,
    required double ev,
  }) {
    return [
      _Flow(
        from: const Offset(.50, .19),
        to: const Offset(.50, .39),
        color: KemsTheme.amber,
        power: solar.abs(),
        active: solar.abs() > .01,
      ),
      _Flow(
        from: const Offset(.22, .48),
        to: const Offset(.40, .48),
        color: KemsTheme.blue,
        power: math.max(gridImport, gridExport).abs(),
        active: gridImport.abs() + gridExport.abs() > .01,
        reverse: gridExport > gridImport,
      ),
      _Flow(
        from: const Offset(.60, .48),
        to: const Offset(.78, .48),
        color: KemsTheme.purple,
        power: home.abs(),
        active: home.abs() > .01,
      ),
      _Flow(
        from: const Offset(.50, .49),
        to: const Offset(.50, .57),
        color: KemsTheme.green,
        power: battery.abs(),
        active: battery.abs() > .01,
        reverse: battery < 0,
      ),
      _Flow(
        from: const Offset(.50, .75),
        to: const Offset(.50, .81),
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
    required Color color,
    required bool active,
  }) {
    const width = 118.0;
    const height = 90.0;
    return Positioned(
      left: size.width * point.dx - width / 2,
      top: size.height * point.dy - height / 2,
      width: width,
      height: height,
      child: _FlowNode(
        icon: icon,
        label: label,
        value: value,
        color: color,
        active: active,
      ),
    );
  }

  String _format(double value) {
    if (value == 0) {
      return '0';
    }
    return value.abs().toStringAsFixed(1);
  }
}

class _FlowNode extends StatelessWidget {
  const _FlowNode({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.active,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? .14 : .055),
        border: Border.all(
          color: color.withValues(alpha: active ? .80 : .25),
          width: active ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(17),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: .16),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? color : color.withValues(alpha: .55), size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
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
        ..strokeWidth = flow.active ? 3 : 2
        ..color = flow.color.withValues(alpha: flow.active ? .28 : .08);
      canvas.drawPath(path, basePaint);

      if (!flow.active) {
        continue;
      }
      final metric = path.computeMetrics().first;
      final speed = (.55 + math.min(flow.power.abs(), 10) / 10 * 1.45);
      final directionProgress = (progress * speed) % 1;
      final baseProgress = flow.reverse ? 1 - directionProgress : directionProgress;
      final count = 4 + math.min(flow.power.abs().round(), 5);
      for (var index = 0; index < count; index++) {
        var position = (baseProgress + index / count) % 1;
        if (flow.reverse) {
          position = 1 - position;
        }
        final tangent = metric.getTangentForOffset(metric.length * position);
        if (tangent == null) {
          continue;
        }
        final radius = 3.2 + math.min(flow.power.abs(), 8) * .12;
        canvas.drawCircle(
          tangent.position,
          radius * 2.6,
          Paint()..color = flow.color.withValues(alpha: .08),
        );
        canvas.drawCircle(
          tangent.position,
          radius,
          Paint()..color = flow.color.withValues(alpha: .92),
        );
      }
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
