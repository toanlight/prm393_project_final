import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/models/chart_models.dart';

class ExpensePieChart extends StatefulWidget {
  final List<PieSegment> data;

  const ExpensePieChart({super.key, required this.data});

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 45, // Donut effect
          sections: _showingSections(),
        ),
      ),
    );
  }

  List<PieChartSectionData> _showingSections() {
    return List.generate(widget.data.length, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 65.0 : 55.0; // Highlight on touch
      final item = widget.data[i];

      return PieChartSectionData(
        color: item.color,
        value: item.value,
        title: '',
        showTitle: false,
        radius: radius,
      );
    });
  }
}
