import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/cat_record.dart';

class WeightChart extends StatelessWidget {
  final List<CatRecord> records;
  const WeightChart({super.key, required this.records});

  // 월별 평균 계산
  List<MapEntry<DateTime, double>> _monthlyAverage() {
    final Map<String, List<double>> grouped = {};

    for (final r in records) {
      // 연-월만 추출
      final key = DateFormat('yyyy-MM').format(r.timestamp);
      grouped.putIfAbsent(key, () => []).add(r.weight);
    }

    // 월별 평균 계산 후 정렬
    final result = grouped.entries.map((e) {
      final date = DateTime.parse('${e.key}-01');
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return MapEntry(date, avg);
    }).toList();

    result.sort((a, b) => a.key.compareTo(b.key));

    // 최근 6개월만 표시
    return result.length > 6 ? result.sublist(result.length - 6) : result;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final monthlyData = _monthlyAverage();

    if (monthlyData.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
            child: Text('기록이 없습니다.',
                style: TextStyle(color: cs.onSurfaceVariant))),
      );
    }

    final weights = monthlyData.map((e) => e.value).toList();
    final minY =
        (weights.reduce((a, b) => a < b ? a : b) - 0.2).clamp(0.0, 99.0);
    final maxY = weights.reduce((a, b) => a > b ? a : b) + 0.2;
    final spots = monthlyData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: LineChart(LineChartData(
        minY: minY,
        maxY: maxY,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false, reservedSize: 70)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
              sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (val, _) => Text(val.toStringAsFixed(2),
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
          )),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (val, _) {
              final idx = val.toInt();
              if (idx < 0 || idx >= monthlyData.length) return const SizedBox();
              // 월만 표시 (예: 6월)
              return Text(DateFormat('M월').format(monthlyData[idx].key),
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant));
            },
          )),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 0.2,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: cs.outlineVariant.withOpacity(0.3), strokeWidth: 1),
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
                    strokeWidth: 2)),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  cs.primary.withOpacity(0.18),
                  cs.primary.withOpacity(0.01)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          )
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final entry = monthlyData[s.x.toInt()];
              return LineTooltipItem(
                // 툴팁: 몇월 + 평균 체중
                '${DateFormat('yyyy년 M월').format(entry.key)}\n평균 ${entry.value.toStringAsFixed(2)} kg',
                TextStyle(
                    color: cs.onPrimaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
      )),
    );
  }
}
