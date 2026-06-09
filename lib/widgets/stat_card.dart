import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const StatCard({super.key, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 20, color: cs.primary),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: [const FontFeature.tabularFigures()])),
            Text(label,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ]),
        ],
      ),
    );
  }
}
