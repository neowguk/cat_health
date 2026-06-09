import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/cat_record.dart';
import '../providers/cat_provider.dart';

class RecordList extends StatelessWidget {
  final List<CatRecord> records;
  final bool compact;
  const RecordList({super.key, required this.records, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final shown = compact ? records.take(5).toList() : records;
    if (shown.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text('저장된 기록이 없습니다.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
      );
    }
    return Column(children: shown.map((r) => _RecordItem(record: r)).toList());
  }
}

class _RecordItem extends StatelessWidget {
  final CatRecord record;
  const _RecordItem({required this.record});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fmt = DateFormat('MM/dd HH:mm');
    final status = record.weight >= 6 ? '체중 주의'
        : record.weight < 3 ? '저체중 주의' : '안정';
    final statusColor = (record.weight >= 6 || record.weight < 3) ? cs.error : cs.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: const Icon(Icons.pets, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(record.catName,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(fmt.format(record.timestamp),
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: [
            _pill(context, '${record.weight.toStringAsFixed(2)} kg'),
            _pill(context, '${record.temperature.toStringAsFixed(1)} °C'),
          ]),
        ])),
        Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status,
                style: tt.labelSmall?.copyWith(
                    color: statusColor, fontWeight: FontWeight.w700)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: cs.error,
            onPressed: () {
              if (record.id != null) {
                context.read<CatProvider>().deleteRecord(record.id!);
              }
            },
          ),
        ]),
      ]),
    );
  }

  Widget _pill(BuildContext ctx, String text) {
    final cs = Theme.of(ctx).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}
