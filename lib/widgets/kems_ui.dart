import 'package:flutter/material.dart';
import '../models/ha_entity.dart';
import '../state/app_controller.dart';
import '../theme/kems_theme.dart';

class KemsPage extends StatelessWidget {
  const KemsPage({super.key, required this.children, this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 110)});
  final List<Widget> children;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async {},
    child: ListView(padding: padding, children: children),
  );
}

class KemsCard extends StatelessWidget {
  const KemsCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.glow});
  final Widget child;
  final EdgeInsets padding;
  final Color? glow;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: KemsTheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: glow?.withValues(alpha: .45) ?? const Color(0xFF1C2D34)),
      boxShadow: glow == null ? null : [BoxShadow(color: glow!.withValues(alpha: .10), blurRadius: 24)],
    ),
    child: child,
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 10),
    child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))), ?trailing]),
  );
}

class LivePill extends StatelessWidget {
  const LivePill({super.key, required this.connected});
  final bool connected;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: (connected ? KemsTheme.green : KemsTheme.red).withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7, decoration: BoxDecoration(color: connected ? KemsTheme.green : KemsTheme.red, shape: BoxShape.circle)),
      const SizedBox(width: 7),
      Text(connected ? 'Live' : 'Reconnecting', style: TextStyle(color: connected ? KemsTheme.green : KemsTheme.red, fontWeight: FontWeight.w700, fontSize: 12)),
    ]),
  );
}

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value, required this.icon, required this.color, this.caption});
  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => KemsCard(
    padding: const EdgeInsets.all(13),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: color, size: 20), const Spacer(), Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11))]),
      const SizedBox(height: 10),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      if (caption != null) ...[const SizedBox(height: 3), Text(caption!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 11))],
    ]),
  );
}

String displayEntity(AppController c, String id, {String fallback = '—', int decimals = 1}) {
  final HaEntity? e = c.entity(id);
  if (e == null || e.state == 'unknown' || e.state == 'unavailable') {
    return fallback;
  }
  final n = e.numericState;
  if (n == null) {
    return e.state;
  }
  return '${n.toStringAsFixed(decimals)}${e.unit.isEmpty ? '' : ' ${e.unit}'}';
}

class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
    Image.asset('assets/branding/kems_mark.png', width: 38, height: 38),
    const SizedBox(width: 8),
    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('KEMS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      Text('COMPANION', style: TextStyle(fontSize: 8, color: KemsTheme.green, fontWeight: FontWeight.w800, letterSpacing: 2)),
    ]),
  ]);
}
