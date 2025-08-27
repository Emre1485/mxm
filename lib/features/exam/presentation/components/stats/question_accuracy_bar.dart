import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class QuestionAccuracyBar extends StatelessWidget {
  /// questions: {qid: {'questionText': '...', ...}}
  /// correctCountPerQuestion: {qid: 7}
  /// totalStudents: 12
  final Map<String, dynamic> questions;
  final Map<String, int> correctCountPerQuestion;
  final int totalStudents;
  final double height;

  const QuestionAccuracyBar({
    super.key,
    required this.questions,
    required this.correctCountPerQuestion,
    required this.totalStudents,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty || totalStudents <= 0) {
      return const Text('Veri yok.');
    }
    final qEntries = questions.entries.toList();
    // max 10 çubukla sınırlayalım (ilk sürüm minimal)
    final show = qEntries.take(10).toList();

    final bars = <BarChartGroupData>[];
    for (var i = 0; i < show.length; i++) {
      final qid = show[i].key;
      final correct = correctCountPerQuestion[qid] ?? 0;
      final ratio = (correct / totalStudents) * 100;
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: ratio,
              width: 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          barGroups: bars,
          maxY: 100,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: 25,
                getTitlesWidget: (v, _) => Text('%${v.toInt()}'),
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= show.length)
                    return const SizedBox.shrink();
                  final title = 'S${idx + 1}';
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(title),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
