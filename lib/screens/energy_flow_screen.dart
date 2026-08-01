import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../theme/kems_theme.dart';
import '../widgets/kems_ui.dart';

class EnergyFlowScreen extends StatefulWidget {
  const EnergyFlowScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<EnergyFlowScreen> createState() => _EnergyFlowScreenState();
}

class _EnergyFlowScreenState extends State<EnergyFlowScreen> with SingleTickerProviderStateMixin {
  late final AnimationController pulse;
  @override
  void initState() { super.initState(); pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true); }
  @override
  void dispose() { pulse.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final c = widget.controller; final m = c.mapping;
    return KemsPage(children: [
      const SectionTitle('Energy flow'),
      KemsCard(child: SizedBox(height: 430, child: AnimatedBuilder(animation: pulse, builder: (context, _) => Stack(children: [
        Positioned(top: 8, left: 0, right: 0, child: _node(Icons.wb_sunny, 'Solar', displayEntity(c, m.solarPower), KemsTheme.amber)),
        Positioned(top: 170, left: 0, child: _node(Icons.electric_meter, 'Grid', displayEntity(c, m.gridNetPower), KemsTheme.blue)),
        Positioned(top: 170, right: 0, child: _node(Icons.home, 'Home', displayEntity(c, m.houseLoad), KemsTheme.purple)),
        Positioned(top: 155, left: 0, right: 0, child: Center(child: _node(Icons.battery_charging_full, 'Battery', displayEntity(c, m.batterySoc), KemsTheme.green))),
        Positioned(bottom: 6, left: 0, right: 0, child: Center(child: _node(Icons.electric_car, 'EV', displayEntity(c, m.evPower), KemsTheme.cyan))),
        ..._lines(pulse.value),
      ]))),
      const SizedBox(height: 14),
      KemsCard(child: Row(children: [const Icon(Icons.eco_outlined, color: KemsTheme.green), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Energy independence', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(8), child: const LinearProgressIndicator(value: .72, minHeight: 9)), const SizedBox(height: 6), const Text('72% powered without peak-rate grid energy', style: TextStyle(color: Colors.white54, fontSize: 12))]))])),
    ]);
  }
  Widget _node(IconData icon, String name, String value, Color color) => Container(width: 112, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: .08), border: Border.all(color: color.withValues(alpha: .6)), borderRadius: BorderRadius.circular(16)), child: Column(children: [Icon(icon, color: color), const SizedBox(height: 6), Text(name, style: TextStyle(color: color, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]));
  List<Widget> _lines(double t) { final a=.25+t*.45; return [
    Positioned(top: 106,left: 0,right: 0,child: Center(child: _arrow(Icons.arrow_downward,KemsTheme.amber,a))),
    Positioned(top: 210,left: 105,child: _arrow(Icons.arrow_forward,KemsTheme.blue,a)),
    Positioned(top: 210,right: 105,child: _arrow(Icons.arrow_forward,KemsTheme.green,a)),
    Positioned(bottom: 102,left: 0,right: 0,child: Center(child: _arrow(Icons.arrow_downward,KemsTheme.cyan,a))),
  ]; }
  Widget _arrow(IconData i,Color c,double a)=>Icon(i,color:c.withValues(alpha:a),size:34);
}
