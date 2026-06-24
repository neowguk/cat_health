import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/cat_record.dart';
import '../providers/cat_provider.dart';
import 'weight_chart.dart';

class RecordList extends StatefulWidget {
  final List<CatRecord> records;
  final bool compact;
  const RecordList({super.key, required this.records, this.compact = false});

  @override
  State<RecordList> createState() => _RecordListState();
}

class _RecordListState extends State<RecordList> {
  int _currentPage = 0;
  final int _perPage = 9;

  @override
  void didUpdateWidget(covariant RecordList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.records != widget.records) _currentPage = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      final shown = widget.records.take(5).toList();
      if (shown.isEmpty) return _empty(context);
      return Column(
        children: shown.map((r) => _RecordItem(record: r)).toList(),
      );
    }

    if (widget.records.isEmpty) return _empty(context);

    final totalPages = (widget.records.length / _perPage).ceil();
    final start = _currentPage * _perPage;
    final end = (start + _perPage).clamp(0, widget.records.length);
    final shown = widget.records.sublist(start, end);
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        ...shown.map((r) => _RecordItem(record: r)).toList(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _currentPage > 0
                  ? () => setState(() => _currentPage--)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
              style: IconButton.styleFrom(
                backgroundColor: _currentPage > 0
                    ? cs.primaryContainer
                    : cs.surfaceContainerLow,
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(
                totalPages,
                (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _currentPage = i),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? cs.primary
                                : cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _currentPage == i
                                  ? cs.primary
                                  : cs.outlineVariant.withOpacity(0.5),
                            ),
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _currentPage == i
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant,
                                )),
                          ),
                        ),
                      ),
                    )),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _currentPage < totalPages - 1
                  ? () => setState(() => _currentPage++)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
              style: IconButton.styleFrom(
                backgroundColor: _currentPage < totalPages - 1
                    ? cs.primaryContainer
                    : cs.surfaceContainerLow,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${start + 1}-$end / 총 ${widget.records.length}개',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _empty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
          child: Text('저장된 기록이 없습니다.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant))),
    );
  }
}

class _RecordItem extends StatelessWidget {
  final CatRecord record;
  const _RecordItem({required this.record});

  // 고양이 이름 클릭 시 추이 바텀시트
  void _showChart(BuildContext context) {
    final allRecords = context.read<CatProvider>().records;
    final catRecords =
        allRecords.where((r) => r.catName == record.catName).toList();
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 제목
            Row(children: [
              CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: const Icon(Icons.pets, size: 18),
              ),
              const SizedBox(width: 10),
              Text('${record.catName} 체중 추이',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
            ]),
            const SizedBox(height: 20),
            // 차트
            WeightChart(records: catRecords),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '최근 6개월 월별 평균 체중',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fmt = DateFormat('MM/dd HH:mm');
    final status = record.weight >= 6
        ? '체중 주의'
        : record.weight < 3
            ? '저체중 주의'
            : '안정';
    final statusColor =
        (record.weight >= 6 || record.weight < 3) ? cs.error : cs.primary;

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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ 고양이 이름 클릭 시 추이 바텀시트
              GestureDetector(
                onTap: () => _showChart(context),
                child: Row(children: [
                  Text(record.catName,
                      style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700, color: cs.primary)),
                  const SizedBox(width: 4),
                  Icon(Icons.show_chart_rounded, size: 14, color: cs.primary),
                ]),
              ),
              const SizedBox(height: 2),
              Text(fmt.format(record.timestamp),
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: [
                _pill(context, '${record.weight.toStringAsFixed(2)} kg'),
              ]),
            ],
          ),
        ),
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
