import 'package:flutter/material.dart';

import '../models/ha_entity.dart';
import '../state/app_controller.dart';
import '../theme/kems_theme.dart';

class KemsPage extends StatelessWidget {
  const KemsPage({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 110),
    this.onRefresh,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: children,
    );
    if (onRefresh == null) {
      return list;
    }
    return RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

class KemsCard extends StatelessWidget {
  const KemsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.glow,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: KemsTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: glow?.withValues(alpha: .45) ?? const Color(0xFF1C2D34),
        ),
        boxShadow: glow == null
            ? null
            : [
                BoxShadow(
                  color: glow!.withValues(alpha: .10),
                  blurRadius: 24,
                ),
              ],
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class LivePill extends StatelessWidget {
  const LivePill({super.key, required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected ? KemsTheme.green : KemsTheme.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            connected ? 'Live' : 'Reconnecting',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return KemsCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          if (caption != null) ...[
            const SizedBox(height: 3),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class EntityDirectory extends StatelessWidget {
  const EntityDirectory({
    super.key,
    required this.entities,
    required this.accent,
  });

  final List<HaEntity> entities;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (entities.isEmpty) {
      return const KemsCard(
        child: Text(
          'No matching KEMS entities are available yet.',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }
    return KemsCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < entities.length; index++) ...[
            _EntityRow(entity: entities[index], accent: accent),
            if (index != entities.length - 1)
              const Divider(height: 1, indent: 54, endIndent: 14),
          ],
        ],
      ),
    );
  }
}

class _EntityRow extends StatelessWidget {
  const _EntityRow({required this.entity, required this.accent});

  final HaEntity entity;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final name = entity.friendlyName.isNotEmpty
        ? entity.friendlyName.replaceFirst('KEMS ', '')
        : entity.entityId.replaceFirst(RegExp(r'^(sensor|binary_sensor)\.kems_'), '').replaceAll('_', ' ');
    final unavailable = entity.state == 'unknown' || entity.state == 'unavailable';
    final state = entity.unit.isEmpty ? entity.state : '${entity.state} ${entity.unit}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              entity.entityId.startsWith('binary_sensor.')
                  ? Icons.toggle_on_outlined
                  : Icons.analytics_outlined,
              size: 17,
              color: unavailable ? Colors.white30 : accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  entity.entityId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white30, fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            unavailable ? 'Unavailable' : state,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: unavailable ? Colors.white30 : Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

String displayEntity(
  AppController controller,
  String id, {
  String fallback = '—',
  int decimals = 1,
}) {
  final entity = controller.entity(id);
  if (entity == null || entity.state == 'unknown' || entity.state == 'unavailable') {
    return fallback;
  }
  final number = entity.numericState;
  if (number == null) {
    return entity.state;
  }
  return '${number.toStringAsFixed(decimals)}${entity.unit.isEmpty ? '' : ' ${entity.unit}'}';
}

class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/branding/kems_mark.png',
          width: 38,
          height: 38,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(width: 8),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KEMS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'COMPANION',
              style: TextStyle(
                fontSize: 8,
                color: KemsTheme.green,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
