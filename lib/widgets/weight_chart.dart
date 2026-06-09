import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/cat_record.dart';

class WeightChart extends StatelessWidget {
  final List<CatRecord> records;
  const WeightChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sorted = [...records]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final data = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;

    if (data.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(child: Text('기록이 없습니다.',
            style: TextStyle(color: cs.onSurfaceVariant))),
      );
    }

    final weights = data.map((r) => r.weight).toList();
    final minY = (weights.reduce((a, b) => a < b ? a : b) - 0.2).clamp(0.0, 99.0);
    final maxY = weights.reduce((a, b) => a > b ? a : b) + 0.2;
    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
        .toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: LineChart(LineChartData(
        minY: minY, maxY: maxY,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 48,
            getTitlesWidget: (val, _) => Text(val.toStringAsFixed(2),
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 30,
            getTitlesWidget: (val, _) {
              final idx = val.toInt();
              if (idx < 0 || idx >= data.length) return const SizedBox();
              return Text(DateFormat('M/d').format(data[idx].timestamp),
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant));
            },
          )),
        ),
        gridData: FlGridData(
          show: true, horizontalInterval: 0.2, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: cs.outlineVariant.withOpacity(0.3), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [LineChartBarData(
          spots: spots, isCurved: true, curveSmoothness: 0.35,
          color: cs.primary, barWidth: 3,
          dotData: FlDotData(getDotPainter: (_, __, ___, ____) =>
              FlDotCirclePainter(radius: 4, color: Colors.white,
                  strokeColor: cs.primary, strokeWidth: 2)),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [cs.primary.withOpacity(0.18), cs.primary.withOpacity(0.01)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
        )],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final r = data[s.x.toInt()];
              return LineTooltipItem(
                '${r.catName}\n${r.weight.toStringAsFixed(2)} kg',
                TextStyle(color: cs.onPrimaryContainer, fontSize: 12,
                    fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
      )),
    );
  }
}
