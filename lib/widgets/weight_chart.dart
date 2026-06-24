import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/cat_record.dart';

class WeightChart extends StatelessWidget {
  final List<CatRecord> records;
  const WeightChart({super.key, required this.records});

  List<MapEntry<DateTime, double>> _intervalAverage() {
    if (records.isEmpty) return [];

    final sorted = [...records]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final oldest = sorted.first.timestamp;

    final Map<int, List<double>> grouped = {};
    for (final r in sorted) {
      final diff = r.timestamp.difference(oldest).inDays;
      final bucket = diff ~/ 3;
      grouped.putIfAbsent(bucket, () => []).add(r.weight);
    }

    final result = grouped.entries.map((e) {
      final date = oldest.add(Duration(days: e.key * 3));
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return MapEntry(date, avg);
    }).toList();

    result.sort((a, b) => a.key.compareTo(b.key));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = _intervalAverage();

    if (data.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child:
              Text('기록이 없습니다.', style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      );
    }

    final weights = data.map((e) => e.value).toList();
    final rawMin = weights.reduce((a, b) => a < b ? a : b);
    final rawMax = weights.reduce((a, b) => a > b ? a : b);

    final minY = ((rawMin - 0.2) * 10).floorToDouble() / 10;
    final maxY = ((rawMax + 0.2) * 10).ceilToDouble() / 10;

    final range = maxY - minY;
    double yInterval;
    if (range <= 0.4) {
      yInterval = 0.1;
    } else if (range <= 1.0) {
      yInterval = 0.2;
    } else if (range <= 2.0) {
      yInterval = 0.5;
    } else {
      yInterval = 1.0;
    }

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    return Container(
      height: 240, // ✅ 220 → 240 공간 확보
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), // ✅ 하단 패딩 추가
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),

            // ✅ Y축 — interval 명시 + 여유 간격
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56, // ✅ 레이블 잘림 방지
                interval: yInterval,
                getTitlesWidget: (val, meta) {
                  if (val == meta.min || val == meta.max) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(left: 8), // ✅ 점과 간격
                    child: Text(
                      '${val.toStringAsFixed(2)}kg',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),

            // ✅ X축 — 마지막 두 레이블 겹침 방지
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34, // ✅ 30 → 34
                interval: 1,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();

                  final isFirst = idx == 0;
                  final isLast = idx == data.length - 1;
                  final isSecondToLast = idx == data.length - 2;
                  final step = (data.length / 6).ceil().clamp(1, 99);

                  // ✅ 마지막에서 두 번째는 항상 숨겨서 끝 레이블 겹침 방지
                  if (isSecondToLast) return const SizedBox();
                  if (!isFirst && !isLast && idx % step != 0) {
                    return const SizedBox();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('M/d').format(data[idx].key),
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: yInterval, // ✅ Y축과 동일 간격
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: cs.outlineVariant.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: cs.primary,
              barWidth: 3,
              dotData: FlDotData(
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeColor: cs.primary,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withOpacity(0.18),
                    cs.primary.withOpacity(0.01),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final entry = data[s.x.toInt()];
                return LineTooltipItem(
                  '${DateFormat('M월 d일').format(entry.key)}\n평균 ${entry.value.toStringAsFixed(2)} kg',
                  TextStyle(
                    color: cs.onPrimaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
