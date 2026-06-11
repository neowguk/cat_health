import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/cat_provider.dart';

class HealthStatusCard extends StatelessWidget {
  final CatProvider prov;
  const HealthStatusCard({super.key, required this.prov});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final latest = prov.latestOfSelected;
    final delta = prov.weightDelta;
    final fmt = DateFormat('MM/dd HH:mm');

    String title, body;
    if (latest == null) {
      title = '기록을 먼저 저장해 주세요.';
      body = '첫 기록이 쌓이면 자동으로 체중 추세를 분석합니다.';
    } else if (delta != null && delta <= -0.2) {
      title = '최근 체중이 눈에 띄게 감소했습니다.';
      body = '사료량·활동량·음수량을 함께 기록하면 더 정확한 건강 확인이 가능합니다.';
    } else if (delta != null && delta >= 0.2) {
      title = '최근 체중이 빠르게 증가했습니다.';
      body = '간식 섭취량과 운동 빈도를 함께 관찰해 보세요.';
    } else {
      title = '체중 변화가 안정적입니다.';
      body = '같은 시간대에 반복 측정하면 더 정확한 추세를 확인할 수 있습니다.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.smart_toy_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text('실시간 상태 · ${prov.selectedCat}',
              style: tt.labelMedium
                  ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        if (latest != null) ...[
          _row(context, '현재 체중', '${latest.weight.toStringAsFixed(2)} kg'),
          // 온도 삭제 ✅
          _row(context, '마지막 측정', fmt.format(latest.timestamp)),
          _row(
              context,
              '직전 대비',
              delta == null
                  ? '-'
                  : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)} kg'),
          _row(context, '건강 알림',
              (delta != null && delta.abs() >= 0.2) ? '체크 필요' : '정상 범위'),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(body,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ]),
        ),
      ]),
    );
  }

  Widget _row(BuildContext ctx, String label, String value) {
    final cs = Theme.of(ctx).colorScheme;
    final tt = Theme.of(ctx).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        Text(value, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
