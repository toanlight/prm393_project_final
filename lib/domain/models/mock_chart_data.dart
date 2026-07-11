import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// ── KPI ──────────────────────────────────────────────────────────────────────
class KpiData {
  final String label;
  final int    value;       // VND
  final String trend;
  final bool?  trendUp;     // true=up, false=down, null=neutral
  final Color  color;
  final Color  bgColor;
  const KpiData({required this.label, required this.value,
    required this.trend, this.trendUp, required this.color, required this.bgColor});
}

final List<KpiData> kpiCards = [
  KpiData(label:"Tổng Thu",     value:195000000, trend:"+8.4%",  trendUp:true,  color:AppColors.success,   bgColor:AppColors.successBg),
  KpiData(label:"Tổng Chi",     value:83500000,  trend:"-3.2%",  trendUp:false, color:AppColors.danger,    bgColor:AppColors.dangerBg),
  KpiData(label:"Số dư ròng",   value:111500000, trend:"+22.1%", trendUp:true,  color:AppColors.primary,   bgColor:const Color(0xFFDBEAFE)),
  KpiData(label:"Số giao dịch", value:0,         trend:"48 GD",  trendUp:null,  color:AppColors.purple,    bgColor:AppColors.purpleBg),
];

// ── Bar Chart – Thu vs Chi theo tháng ─────────────────────────────────────
class MonthlyBar {
  final String month;
  final double thu; // triệu VND
  final double chi;
  const MonthlyBar(this.month, this.thu, this.chi);
}

final List<MonthlyBar> monthlyData = [
  MonthlyBar("T1", 142, 98),
  MonthlyBar("T2", 165, 120),
  MonthlyBar("T3", 155, 105),
  MonthlyBar("T4", 180, 130),
  MonthlyBar("T5", 175, 118),
  MonthlyBar("T6", 195, 83.5),
];

// ── Pie Chart – Cơ cấu chi phí ───────────────────────────────────────────
class PieSegment {
  final String name;
  final double value; // triệu VND
  final Color  color;
  const PieSegment(this.name, this.value, this.color);
}

final List<PieSegment> spendingData = [
  PieSegment("Lương & phụ cấp",     85,   AppColors.chart1),
  PieSegment("Nguyên vật liệu",      32,   AppColors.chart3),
  PieSegment("Mặt bằng & thuê VP",  18,   AppColors.chart2),
  PieSegment("Marketing & QC",       12,   AppColors.chart5),
  PieSegment("Điện, nước, internet",  4.5, AppColors.chart4),
  PieSegment("Chi phí khác",          8.5, AppColors.chart6),
];

// ── Line Chart – Xu hướng số dư ──────────────────────────────────────────
class TrendPoint {
  final String date;
  final double balance; // triệu VND
  const TrendPoint(this.date, this.balance);
}

final List<TrendPoint> trendData = [
  TrendPoint("1/6",  520),
  TrendPoint("3/6",  485),
  TrendPoint("5/6",  510),
  TrendPoint("7/6",  498),
  TrendPoint("9/6",  540),
  TrendPoint("11/6", 562),
  TrendPoint("12/6", 584),
];
