import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TopicPie extends StatelessWidget {
  /// example: {'Oran Orantı': 8, 'Cebir': 3}
  final Map<String, int> data;
  final double height;

  const TopicPie({super.key, required this.data, this.height = 220});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('Veri yok.');
    }
    final total = data.values.fold<int>(0, (a, b) => a + b);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final percent = total == 0 ? 0.0 : (e.value / total) * 100;
      sections.add(
        PieChartSectionData(
          value: e.value.toDouble(),
          title: '${percent.toStringAsFixed(0)}%',
          radius: 70,
          titleStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 38,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: entries.map((e) {
            final percent = total == 0 ? 0.0 : (e.value / total) * 100;
            return Chip(
              label: Text(
                '${e.key} • ${percent.toStringAsFixed(0)}% (${e.value})',
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
