import 'package:flutter/material.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(active ? Icons.cloud_done : Icons.cloud_off, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ]),
      );
}
