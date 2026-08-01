import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
  });
  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.labelLarge)),
              ]),
              const Spacer(),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      );
}
