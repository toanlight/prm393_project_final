import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/mock_chart_data.dart' hide kpiCards, monthlyData, spendingData, trendData;
import '../../domain/models/mock_chart_data.dart' as mock;
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/repositories/category_repository.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/transaction_provider.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/income_expense_bar_chart.dart';
import '../widgets/income_expense_line_chart.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedFilter = 'Tháng này';
  bool _isLoading = true;
  String? _errorMessage;

  List<CategoryModel> _categories = [];
  List<TransactionModel> _allTransactions = [];

  // Dynanmic state variables computed from transactions
  List<KpiData> kpiCards = [];
  List<MonthlyBar> monthlyData = [];
  List<PieSegment> spendingData = [];
  List<TrendPoint> trendData = [];

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!mounted) return;

      // 1. Fetch Categories
      final categoryRepo = context.read<CategoryRepository>();
      _categories = await categoryRepo.getCategories();

      if (!mounted) return;

      // 2. Fetch Transactions for the current authenticated user
      final auth = context.read<AuthProvider>();
      final userId = auth.user?.uid;
      if (userId != null) {
        await context.read<TransactionProvider>().fetchTransactions(userId);
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Không thể tải dữ liệu từ Firebase: $e";
      });
    }
  }

  void _processDataSync() {
    // Phương án A: Chỉ tính toán và hiển thị các giao dịch ĐÃ PHÊ DUYỆT (status == 'confirmed')
    final confirmedTransactions = _allTransactions.where((tx) => tx.status == 'confirmed').toList();

    // Filter transactions based on selected chip
    final filtered = _getFilteredTransactions(confirmedTransactions);

    // Calculate dynamic KPI Metrics
    kpiCards = _calculateKpis(filtered, confirmedTransactions);

    // Calculate dynamic Monthly comparative data (Last 6 Months)
    monthlyData = _calculateMonthlyData(confirmedTransactions);

    // Calculate dynamic Expenses category distribution
    spendingData = _calculatePieData(filtered);

    // Calculate dynamic Net Balance trend lines
    trendData = _calculateTrendData(filtered, confirmedTransactions);
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> allTxs) {
    final now = DateTime.now();
    return allTxs.where((tx) {
      final date = tx.transactionDate;
      switch (selectedFilter) {
        case 'Tháng này':
          return date.year == now.year && date.month == now.month;
        case 'Tháng trước':
          final prevMonth = now.month == 1 ? 12 : now.month - 1;
          final prevYear = now.month == 1 ? now.year - 1 : now.year;
          return date.year == prevYear && date.month == prevMonth;
        case 'Quý này':
          final currentQuarter = ((now.month - 1) / 3).floor() + 1;
          final txQuarter = ((date.month - 1) / 3).floor() + 1;
          return date.year == now.year && txQuarter == currentQuarter;
        case 'Toàn bộ':
        default:
          return true;
      }
    }).toList();
  }

  int _getSumForPeriod(List<TransactionModel> txs, TransactionType type) {
    return txs
        .where((tx) => tx.type == type)
        .fold<int>(0, (sum, tx) => sum + tx.amount);
  }

  List<TransactionModel> _getPreviousPeriodTransactions(List<TransactionModel> allTxs) {
    final now = DateTime.now();
    return allTxs.where((tx) {
      final date = tx.transactionDate;
      switch (selectedFilter) {
        case 'Tháng này':
          final prevMonth = now.month == 1 ? 12 : now.month - 1;
          final prevYear = now.month == 1 ? now.year - 1 : now.year;
          return date.year == prevYear && date.month == prevMonth;
        case 'Tháng trước':
          final twoMonthsAgoMonth = now.month <= 2 ? now.month + 10 : now.month - 2;
          final twoMonthsAgoYear = now.month <= 2 ? now.year - 1 : now.year;
          return date.year == twoMonthsAgoYear && date.month == twoMonthsAgoMonth;
        case 'Quý này':
          final currentQuarter = ((now.month - 1) / 3).floor() + 1;
          final prevQuarter = currentQuarter == 1 ? 4 : currentQuarter - 1;
          final prevQuarterYear = currentQuarter == 1 ? now.year - 1 : now.year;
          final txQuarter = ((date.month - 1) / 3).floor() + 1;
          return date.year == prevQuarterYear && txQuarter == prevQuarter;
        default:
          return false;
      }
    }).toList();
  }

  List<KpiData> _calculateKpis(List<TransactionModel> filtered, List<TransactionModel> all) {
    final income = _getSumForPeriod(filtered, TransactionType.income);
    final expense = _getSumForPeriod(filtered, TransactionType.expense);
    final balance = income - expense;

    final prevTxs = _getPreviousPeriodTransactions(all);
    final prevIncome = _getSumForPeriod(prevTxs, TransactionType.income);
    final prevExpense = _getSumForPeriod(prevTxs, TransactionType.expense);
    final prevBalance = prevIncome - prevExpense;

    String getTrendStr(int current, int prev) {
      if (prev == 0) return current == 0 ? "0%" : "+100%";
      final pct = ((current - prev) / prev) * 100;
      final sign = pct >= 0 ? "+" : "";
      return "$sign${pct.toStringAsFixed(1)}%";
    }

    bool? getTrendUp(int current, int prev) {
      if (current == prev) return null;
      return current > prev;
    }

    return [
      KpiData(
        label: "Tổng Thu",
        value: income,
        trend: getTrendStr(income, prevIncome),
        trendUp: getTrendUp(income, prevIncome),
        color: AppColors.success,
        bgColor: AppColors.successBg,
      ),
      KpiData(
        label: "Tổng Chi",
        value: expense,
        trend: getTrendStr(expense, prevExpense),
        trendUp: getTrendUp(expense, prevExpense) == null ? null : !getTrendUp(expense, prevExpense)!,
        color: AppColors.danger,
        bgColor: AppColors.dangerBg,
      ),
      KpiData(
        label: "Số dư ròng",
        value: balance,
        trend: getTrendStr(balance, prevBalance),
        trendUp: getTrendUp(balance, prevBalance),
        color: AppColors.primary,
        bgColor: const Color(0xFFDBEAFE),
      ),
      KpiData(
        label: "Số giao dịch",
        value: filtered.length,
        trend: "${filtered.length} GD",
        trendUp: null,
        color: AppColors.purple,
        bgColor: AppColors.purpleBg,
      ),
    ];
  }

  List<MonthlyBar> _calculateMonthlyData(List<TransactionModel> allTxs) {
    final now = DateTime.now();
    final list = <MonthlyBar>[];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthName = "T${date.month}";
      final monthTxs = allTxs.where((tx) =>
          tx.transactionDate.year == date.year &&
          tx.transactionDate.month == date.month).toList();
      final income = _getSumForPeriod(monthTxs, TransactionType.income) / 1000000.0;
      final expense = _getSumForPeriod(monthTxs, TransactionType.expense) / 1000000.0;
      list.add(MonthlyBar(monthName, income, expense));
    }
    return list;
  }

  List<PieSegment> _calculatePieData(List<TransactionModel> filtered) {
    final expenses = filtered.where((tx) => tx.type == TransactionType.expense).toList();
    if (expenses.isEmpty) return [];

    final Map<String, double> categorySums = {};
    final catMap = {for (var c in _categories) c.categoryId: c};

    for (var tx in expenses) {
      final cat = catMap[tx.categoryId];
      final name = cat?.categoryName ?? 'Chi phí khác';
      categorySums[name] = (categorySums[name] ?? 0.0) + (tx.amount / 1000000.0);
    }

    final list = <PieSegment>[];
    int colorIdx = 0;
    final colors = [
      AppColors.chart1,
      AppColors.chart2,
      AppColors.chart3,
      AppColors.chart4,
      AppColors.chart5,
      AppColors.chart6,
      AppColors.purple,
      AppColors.primary,
    ];

    categorySums.forEach((name, value) {
      final color = colors[colorIdx % colors.length];
      list.add(PieSegment(name, value, color));
      colorIdx++;
    });
    return list;
  }

  List<TrendPoint> _calculateTrendData(List<TransactionModel> filtered, List<TransactionModel> all) {
    final filteredSorted = List<TransactionModel>.from(filtered);
    filteredSorted.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

    double startingBalance = 0.0;
    if (filteredSorted.isNotEmpty) {
      final firstDate = filteredSorted.first.transactionDate;
      final priorTxs = all.where((tx) => tx.transactionDate.isBefore(firstDate)).toList();
      final priorIncome = _getSumForPeriod(priorTxs, TransactionType.income);
      final priorExpense = _getSumForPeriod(priorTxs, TransactionType.expense);
      startingBalance = (priorIncome - priorExpense) / 1000000.0;
    }

    final points = <TrendPoint>[];
    double currentBalance = startingBalance;
    final Map<String, double> dailyNet = {};

    for (var tx in filteredSorted) {
      final dateStr = "${tx.transactionDate.day}/${tx.transactionDate.month}";
      final amountM = tx.amount / 1000000.0;
      final change = tx.type == TransactionType.income ? amountM : -amountM;
      dailyNet[dateStr] = (dailyNet[dateStr] ?? 0.0) + change;
    }

    if (dailyNet.isEmpty) {
      final now = DateTime.now();
      points.add(TrendPoint("${now.day}/${now.month}", currentBalance));
    } else {
      dailyNet.forEach((date, change) {
        currentBalance += change;
        points.add(TrendPoint(date, currentBalance));
      });
    }

    if (points.length == 1) {
      final first = points.first;
      points.insert(0, TrendPoint("Đầu kỳ", first.balance));
    }

    return points;
  }

  String _getCurrentDateRangeString() {
    final now = DateTime.now();
    switch (selectedFilter) {
      case 'Tháng này':
        return 'Tháng ${now.month}/${now.year}';
      case 'Tháng trước':
        final prev = DateTime(now.year, now.month - 1, 1);
        return 'Tháng ${prev.month}/${prev.year}';
      case 'Quý này':
        return 'Quý ${((now.month - 1) / 3).floor() + 1}/${now.year}';
      case 'Toàn bộ':
      default:
        return 'Toàn thời gian';
    }
  }

  String _getLastUpdatedTimeString() {
    final now = DateTime.now();
    final minuteStr = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'CH' : 'SA';
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    return '$hour:$minuteStr $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Auto-listen to TransactionProvider so Dashboard updates INSTANTLY when transactions change
    final txProvider = context.watch<TransactionProvider>();
    _allTransactions = txProvider.transactions;
    _processDataSync();

    return Scaffold(
      backgroundColor: isDark ? AppDesignTokens.darkBackground : AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.sp24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                        const SizedBox(height: AppTheme.sp16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h2.copyWith(color: AppColors.danger),
                        ),
                        const SizedBox(height: AppTheme.sp24),
                        ElevatedButton(
                          onPressed: _initDashboard,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _initDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppTheme.sp24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: AppTheme.sp24),
                        AppResponsiveLayout(
                          mobile: _buildMobileLayout(context),
                          desktop: _buildDesktopLayout(context),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppDesignTokens.darkTextPrimary : AppColors.foreground;
    final mutedTextColor = isDark ? AppDesignTokens.darkTextSecondary : AppColors.mutedFg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tổng quan', style: AppTextStyles.h1.copyWith(color: textColor)),
        const SizedBox(height: AppTheme.sp4),
        Text(
          '${_getCurrentDateRangeString()} - cập nhật lúc ${_getLastUpdatedTimeString()}',
          style: AppTextStyles.caption.copyWith(color: mutedTextColor),
        ),
        const SizedBox(height: AppTheme.sp24),
        _buildFilterChips(context),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? AppDesignTokens.darkSurface : AppColors.card;
    final chipBorder = isDark ? AppDesignTokens.darkBorder : AppColors.border;
    final unselectedText = isDark ? AppDesignTokens.darkTextSecondary : AppColors.mutedFg;

    final filters = ['Tháng này', 'Tháng trước', 'Quý này', 'Toàn bộ'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.sp8),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedFilter = filter;
                  _processDataSync();
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : chipBg,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? null : Border.all(color: chipBorder),
                ),
                child: Text(
                  filter,
                  style: AppTextStyles.body.copyWith(
                    color: isSelected ? AppColors.primaryFg : unselectedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI Cards Row
        Row(
          children: kpiCards.asMap().entries.map((entry) {
            int idx = entry.key;
            KpiData metric = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: idx == kpiCards.length - 1 ? 0 : AppTheme.sp12,
                ),
                child: KpiCard(data: metric)
                    .animate(delay: (idx * 80).ms)
                    .slideY(begin: 0.1, end: 0),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.sp24),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _buildBarChartCard(context)
                    .animate(delay: 200.ms)
                    .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1)),
              ),
              const SizedBox(width: AppTheme.sp12),
              Expanded(
                flex: 1,
                child: _buildPieChartCard(context)
                    .animate(delay: 280.ms)
                    .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.sp24),
        _buildLineChartCard(context)
            .animate(delay: 360.ms)
            .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI Cards Column
        ...kpiCards.asMap().entries.map((entry) {
          int idx = entry.key;
          KpiData metric = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.sp12),
            child: KpiCard(data: metric)
                .animate(delay: (idx * 80).ms)
                .slideY(begin: 0.1, end: 0),
          );
        }),
        _buildBarChartCard(context)
            .animate(delay: 200.ms)
            .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1)),
        const SizedBox(height: AppTheme.sp12),
        _buildPieChartCard(context)
            .animate(delay: 280.ms)
            .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1)),
        const SizedBox(height: AppTheme.sp12),
        _buildLineChartCard(context)
            .animate(delay: 360.ms)
            .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1)),
      ],
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? AppDesignTokens.darkSurface : AppColors.card,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      border: Border.all(
        color: isDark ? AppDesignTokens.darkBorder : AppColors.border,
        width: 1,
      ),
      boxShadow: isDark ? AppDesignTokens.darkShadow : null,
    );
  }

  Widget _buildBarChartCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppDesignTokens.darkTextPrimary : AppColors.foreground;
    final mutedTextColor = isDark ? AppDesignTokens.darkTextSecondary : AppColors.mutedFg;

    return Container(
      decoration: _cardDecoration(context),
      padding: const EdgeInsets.all(AppTheme.sp24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thu & Chi theo tháng', style: AppTextStyles.h2.copyWith(color: textColor)),
                  const SizedBox(height: AppTheme.sp4),
                  Text('Đơn vị: triệu VND', style: AppTextStyles.caption.copyWith(color: mutedTextColor)),
                ],
              ),
              Row(
                children: [
                  _buildLegendDot(context, AppColors.success, 'Thu'),
                  const SizedBox(width: AppTheme.sp16),
                  _buildLegendDot(context, AppColors.danger, 'Chi'),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp24),
          monthlyData.isEmpty
              ? SizedBox(
                  height: 200,
                  child: Center(child: Text('Không có dữ liệu so sánh', style: AppTextStyles.caption.copyWith(color: mutedTextColor))),
                )
              : IncomeExpenseBarChart(data: monthlyData),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppDesignTokens.darkTextPrimary : AppColors.foreground;
    final mutedTextColor = isDark ? AppDesignTokens.darkTextSecondary : AppColors.mutedFg;

    return Container(
      decoration: _cardDecoration(context),
      padding: const EdgeInsets.all(AppTheme.sp24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cơ cấu chi phí', style: AppTextStyles.h2.copyWith(color: textColor)),
          const SizedBox(height: AppTheme.sp4),
          Text(_getCurrentDateRangeString(), style: AppTextStyles.caption.copyWith(color: mutedTextColor)),
          const SizedBox(height: AppTheme.sp24),
          SizedBox(
            height: 180,
            child: spendingData.isEmpty
                ? Center(child: Text('Không có dữ liệu chi phí', style: AppTextStyles.caption.copyWith(color: mutedTextColor)))
                : ExpensePieChart(data: spendingData),
          ),
          const SizedBox(height: AppTheme.sp24),
          _buildPieLegend(context),
        ],
      ),
    );
  }

  Widget _buildPieLegend(BuildContext context) {
    if (spendingData.isEmpty) return const SizedBox();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppDesignTokens.darkTextSecondary : AppColors.mutedFg;

    return Column(
      children: spendingData.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: e.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.sp8),
                  Text(e.name, style: AppTextStyles.caption.copyWith(color: textColor)),
                ],
              ),
              Text(
                '${e.value.toStringAsFixed(e.value.truncateToDouble() == e.value ? 0 : 1)}tr',
                style: AppTextStyles.monoSm.copyWith(color: e.color),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineChartCard(BuildContext context) {
    final netBalanceTrend = kpiCards.length > 2 ? kpiCards[2].trend : '0%';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppDesignTokens.darkTextPrimary : AppColors.foreground;
    final mutedTextColor = isDark ? AppDesignTokens.darkTextSecondary : AppColors.mutedFg;
    final badgeBg = isDark ? AppColors.primary.withOpacity(0.15) : const Color(0xFFDBEAFE);

    return Container(
      decoration: _cardDecoration(context),
      padding: const EdgeInsets.all(AppTheme.sp24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xu hướng số dư ròng', style: AppTextStyles.h2.copyWith(color: textColor)),
                  const SizedBox(height: AppTheme.sp4),
                  Text(
                    '${_getCurrentDateRangeString()} • Đơn vị: triệu VND',
                    style: AppTextStyles.caption.copyWith(color: mutedTextColor),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: Text(
                  '$netBalanceTrend so với kỳ trước',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp24),
          trendData.isEmpty
              ? SizedBox(
                  height: 150,
                  child: Center(child: Text('Không có dữ liệu xu hướng', style: AppTextStyles.caption.copyWith(color: mutedTextColor))),
                )
              : IncomeExpenseLineChart(data: trendData),
        ],
      ),
    );
  }

  Widget _buildLegendDot(BuildContext context, Color color, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppDesignTokens.darkTextSecondary : AppColors.mutedFg;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTheme.sp4),
        Text(label, style: AppTextStyles.caption.copyWith(color: textColor)),
      ],
    );
  }
}
