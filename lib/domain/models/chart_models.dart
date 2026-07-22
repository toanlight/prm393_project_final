import 'package:flutter/material.dart';

// ── KPI ──────────────────────────────────────────────────────────────────────
class KpiData {
  final String label;
  final int value; // VND
  final String trend;
  final bool? trendUp; // true=up, false=down, null=neutral
  final Color color;
  final Color bgColor;
  const KpiData({
    required this.label,
    required this.value,
    required this.trend,
    this.trendUp,
    required this.color,
    required this.bgColor,
  });
}

// ── Bar Chart – Thu vs Chi theo tháng ─────────────────────────────────────
class MonthlyBar {
  final String month;
  final double thu; // triệu VND
  final double chi;
  const MonthlyBar(this.month, this.thu, this.chi);
}

// ── Pie Chart – Cơ cấu chi phí ───────────────────────────────────────────
class PieSegment {
  final String name;
  final double value; // triệu VND
  final Color color;
  const PieSegment(this.name, this.value, this.color);
}

// ── Line Chart – Xu hướng số dư ──────────────────────────────────────────
class TrendPoint {
  final String date;
  final double balance; // triệu VND
  const TrendPoint(this.date, this.balance);
}
