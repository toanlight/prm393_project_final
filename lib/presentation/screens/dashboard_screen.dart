import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/chart_models.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/services/finance_calculation_service.dart';
import '../../domain/repositories/category_repository.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/transaction_provider.dart';
import '../widgets/connection_status_banner.dart';
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
  int selectedYear = DateTime.now().year;
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
    try {
      if (!mounted) return;

      // 1. Fetch Categories
      final categoryRepo = context.read<CategoryRepository>();
      _categories = await categoryRepo.getCategories();
      if (mounted) {
        setState(() {
          _processDataSync();
        });
      }

      if (!mounted) return;

      // 2. Fetch Transactions for the current authenticated user
      final auth = context.read<AuthProvider>();
      final userId = auth.user?.uid ?? '';
      final roleId = auth.user?.roleId;
      await context.read<TransactionProvider>().fetchTransactions(userId, roleId: roleId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Không thể tải dữ liệu từ Firebase: $e";
        });
      }
    }
  }

  void _processDataSync() {
    // Ưu tiên tính toán các giao dịch đã phê duyệt (confirmed), nếu chưa có thì dùng tất cả giao dịch
    final confirmedTransactions = _allTransactions.where((tx) => tx.status == 'confirmed').toList();
    final txsToCalculate = confirmedTransactions.isNotEmpty ? confirmedTransactions : _allTransactions;

    // Filter transactions based on selected chip
    final filtered = _getFilteredTransactions(txsToCalculate);

    // Calculate dynamic KPI Metrics
    kpiCards = _calculateKpis(filtered, txsToCalculate);

    // Calculate dynamic Monthly comparative data (Weeks, Months, or Year)
    monthlyData = _calculateMonthlyData(txsToCalculate);

    // Calculate dynamic Expenses category distribution
    spendingData = _calculatePieData(filtered);

    // Calculate dynamic Net Balance trend lines
    trendData = _calculateTrendData(filtered, txsToCalculate);
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> allTxs) {
    final now = DateTime.now();
    return allTxs.where((tx) {
      final date = tx.transactionDate;
      if (selectedFilter == 'Tháng này') {
        return date.year == now.year && date.month == now.month;
      } else if (selectedFilter == 'Tháng trước') {
        final prevMonth = now.month == 1 ? 12 : now.month - 1;
        final prevYear = now.month == 1 ? now.year - 1 : now.year;
        return date.year == prevYear && date.month == prevMonth;
      } else if (selectedFilter == 'Quý này') {
        final currentQuarter = ((now.month - 1) / 3).floor() + 1;
        final txQuarter = ((date.month - 1) / 3).floor() + 1;
        return date.year == now.year && txQuarter == currentQuarter;
      } else if (selectedFilter.startsWith('Năm')) {
        return date.year == selectedYear;
      }
      return true;
    }).toList();
  }

  int _getSumForPeriod(List<TransactionModel> txs, TransactionType type) {
    return FinanceCalculationService.calculateSumForPeriod(txs, type);
  }

  List<TransactionModel> _getPreviousPeriodTransactions(List<TransactionModel> allTxs) {
    final now = DateTime.now();
    return allTxs.where((tx) {
      final date = tx.transactionDate;
      if (selectedFilter == 'Tháng này') {
        final prevMonth = now.month == 1 ? 12 : now.month - 1;
        final prevYear = now.month == 1 ? now.year - 1 : now.year;
        return date.year == prevYear && date.month == prevMonth;
      } else if (selectedFilter == 'Tháng trước') {
        final twoMonthsAgoMonth = now.month <= 2 ? now.month + 10 : now.month - 2;
        final twoMonthsAgoYear = now.month <= 2 ? now.year - 1 : now.year;
        return date.year == twoMonthsAgoYear && date.month == twoMonthsAgoMonth;
      } else if (selectedFilter == 'Quý này') {
        final currentQuarter = ((now.month - 1) / 3).floor() + 1;
        final prevQuarter = currentQuarter == 1 ? 4 : currentQuarter - 1;
        final prevQuarterYear = currentQuarter == 1 ? now.year - 1 : now.year;
        final txQuarter = ((date.month - 1) / 3).floor() + 1;
        return date.year == prevQuarterYear && txQuarter == prevQuarter;
      } else if (selectedFilter.startsWith('Năm')) {
        return date.year == (selectedYear - 1);
      }
      return false;
    }).toList();
  }

  List<KpiData> _calculateKpis(List<TransactionModel> filtered, List<TransactionModel> all) {
    final income = _getSumForPeriod(filtered, TransactionType.income);
    final expense = _getSumForPeriod(filtered, TransactionType.expense);
    final balance = FinanceCalculationService.calculateNetBalance(income, expense);

    final prevTxs = _getPreviousPeriodTransactions(all);
    final prevIncome = _getSumForPeriod(prevTxs, TransactionType.income);
    final prevExpense = _getSumForPeriod(prevTxs, TransactionType.expense);
    final prevBalance = FinanceCalculationService.calculateNetBalance(prevIncome, prevExpense);

    String getTrendStr(int current, int prev) {
      return FinanceCalculationService.calculateTrendPercentage(current, prev);
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

    if (selectedFilter == 'Tháng này' || selectedFilter == 'Tháng trước') {
      final targetMonth = selectedFilter == 'Tháng này' ? now.month : (now.month == 1 ? 12 : now.month - 1);
      final targetYear = selectedFilter == 'Tháng này' ? now.year : (now.month == 1 ? now.year - 1 : now.year);

      final monthTxs = allTxs.where((tx) =>
          tx.transactionDate.year == targetYear &&
          tx.transactionDate.month == targetMonth).toList();

      for (int w = 1; w <= 4; w++) {
        final startDay = (w - 1) * 7 + 1;
        final endDay = w == 4 ? 31 : w * 7;

        final weekTxs = monthTxs.where((tx) =>
            tx.transactionDate.day >= startDay &&
            tx.transactionDate.day <= endDay).toList();

        final income = _getSumForPeriod(weekTxs, TransactionType.income) / 1000000.0;
        final expense = _getSumForPeriod(weekTxs, TransactionType.expense) / 1000000.0;
        list.add(MonthlyBar("Tuần $w", income, expense));
      }
    } else if (selectedFilter == 'Quý này') {
      final currentQuarter = ((now.month - 1) / 3).floor() + 1;
      final startMonth = (currentQuarter - 1) * 3 + 1;

      for (int i = 0; i < 3; i++) {
        final m = startMonth + i;
        final monthTxs = allTxs.where((tx) =>
            tx.transactionDate.year == now.year &&
            tx.transactionDate.month == m).toList();

        final income = _getSumForPeriod(monthTxs, TransactionType.income) / 1000000.0;
        final expense = _getSumForPeriod(monthTxs, TransactionType.expense) / 1000000.0;
        list.add(MonthlyBar("Tháng $m", income, expense));
      }
    } else if (selectedFilter.startsWith('Năm')) {
      for (int m = 1; m <= 12; m++) {
        final monthTxs = allTxs.where((tx) =>
            tx.transactionDate.year == selectedYear &&
            tx.transactionDate.month == m).toList();

        final income = _getSumForPeriod(monthTxs, TransactionType.income) / 1000000.0;
        final expense = _getSumForPeriod(monthTxs, TransactionType.expense) / 1000000.0;
        list.add(MonthlyBar("T$m", income, expense));
      }
    }

    return list;
  }

  Color _getCategoryColor(String name) {
    final cleanKey = name.toLowerCase().trim();
    if (cleanKey.contains('mặt bằng') || cleanKey.contains('matbang')) {
      return const Color(0xFFEA580C); // Orange
    }
    if (cleanKey.contains('ăn uống') || cleanKey.contains('anuong')) {
      return const Color(0xFF10B981); // Emerald Green
    }
    if (cleanKey.contains('tiền điện') || cleanKey.contains('tiendien') || cleanKey.contains('điện')) {
      return const Color(0xFFF59E0B); // Amber Yellow
    }
    if (cleanKey.contains('tiền nước') || cleanKey.contains('tiennuoc') || cleanKey.contains('nước')) {
      return const Color(0xFF06B6D4); // Cyan
    }
    if (cleanKey.contains('internet')) {
      return const Color(0xFF3B82F6); // Blue
    }
    if (cleanKey.contains('công tác') || cleanKey.contains('congtac')) {
      return const Color(0xFF8B5CF6); // Violet Purple
    }
    if (cleanKey.contains('văn phòng phẩm') || cleanKey.contains('vanphongpham')) {
      return const Color(0xFFEC4899); // Pink
    }
    if (cleanKey.contains('mua sắm') || cleanKey.contains('muasam')) {
      return const Color(0xFF14B8A6); // Teal
    }
    if (cleanKey.contains('thuê xe') || cleanKey.contains('thuexe')) {
      return const Color(0xFF6366F1); // Indigo
    }
    if (cleanKey.contains('di chuyển') || cleanKey.contains('dichuyen')) {
      return const Color(0xFF64748B); // Slate Grey
    }
    
    // Stable fallback
    final hash = name.hashCode.abs();
    final fallbackColors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
      const Color(0xFF64748B),
    ];
    return fallbackColors[hash % fallbackColors.length];
  }

  List<PieSegment> _calculatePieData(List<TransactionModel> filtered) {
    final expenses = filtered.where((tx) => tx.type == TransactionType.expense).toList();
    if (expenses.isEmpty) return [];

    final Map<String, double> categorySums = {};
    final catMap = {for (var c in _categories) c.categoryId: c};

    for (var tx in expenses) {
      final cat = catMap[tx.categoryId];
      String name = cat?.categoryName ?? (tx.categoryId.startsWith('cat_') ? '' : tx.categoryId);
      if (name.trim().isEmpty) {
        name = 'Chi phí khác';
      }
      categorySums[name] = (categorySums[name] ?? 0.0) + (tx.amount / 1000000.0);
    }

    final list = <PieSegment>[];
    categorySums.forEach((name, value) {
      final color = _getCategoryColor(name);
      list.add(PieSegment(name, value, color));
    });

    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  List<TrendPoint> _calculateTrendData(List<TransactionModel> filtered, List<TransactionModel> all) {
    final now = DateTime.now();
    final points = <TrendPoint>[];

    if (selectedFilter == 'Tháng này' || selectedFilter == 'Tháng trước') {
      final targetMonth = selectedFilter == 'Tháng này' ? now.month : (now.month == 1 ? 12 : now.month - 1);
      final targetYear = selectedFilter == 'Tháng này' ? now.year : (now.month == 1 ? now.year - 1 : now.year);

      final priorTxs = all.where((tx) =>
          tx.transactionDate.isBefore(DateTime(targetYear, targetMonth, 1))).toList();
      final priorIncome = _getSumForPeriod(priorTxs, TransactionType.income);
      final priorExpense = _getSumForPeriod(priorTxs, TransactionType.expense);
      double currentBalance = (priorIncome - priorExpense) / 1000000.0;

      final monthTxs = all.where((tx) =>
          tx.transactionDate.year == targetYear &&
          tx.transactionDate.month == targetMonth).toList();

      for (int w = 1; w <= 4; w++) {
        final startDay = (w - 1) * 7 + 1;
        final endDay = w == 4 ? 31 : w * 7;

        final weekTxs = monthTxs.where((tx) =>
            tx.transactionDate.day >= startDay &&
            tx.transactionDate.day <= endDay).toList();

        final wIncome = _getSumForPeriod(weekTxs, TransactionType.income) / 1000000.0;
        final wExpense = _getSumForPeriod(weekTxs, TransactionType.expense) / 1000000.0;

        currentBalance += (wIncome - wExpense);
        points.add(TrendPoint("Tuần $w", currentBalance));
      }
    } else if (selectedFilter == 'Quý này') {
      final currentQuarter = ((now.month - 1) / 3).floor() + 1;
      final startMonth = (currentQuarter - 1) * 3 + 1;

      final priorTxs = all.where((tx) =>
          tx.transactionDate.isBefore(DateTime(now.year, startMonth, 1))).toList();
      final priorIncome = _getSumForPeriod(priorTxs, TransactionType.income);
      final priorExpense = _getSumForPeriod(priorTxs, TransactionType.expense);
      double currentBalance = (priorIncome - priorExpense) / 1000000.0;

      for (int i = 0; i < 3; i++) {
        final m = startMonth + i;
        final monthTxs = all.where((tx) =>
            tx.transactionDate.year == now.year &&
            tx.transactionDate.month == m).toList();

        final mIncome = _getSumForPeriod(monthTxs, TransactionType.income) / 1000000.0;
        final mExpense = _getSumForPeriod(monthTxs, TransactionType.expense) / 1000000.0;

        currentBalance += (mIncome - mExpense);
        points.add(TrendPoint("Tháng $m", currentBalance));
      }
    } else if (selectedFilter.startsWith('Năm')) {
      final priorTxs = all.where((tx) =>
          tx.transactionDate.isBefore(DateTime(selectedYear, 1, 1))).toList();
      final priorIncome = _getSumForPeriod(priorTxs, TransactionType.income);
      final priorExpense = _getSumForPeriod(priorTxs, TransactionType.expense);
      double currentBalance = (priorIncome - priorExpense) / 1000000.0;

      for (int m = 1; m <= 12; m++) {
        final monthTxs = all.where((tx) =>
            tx.transactionDate.year == selectedYear &&
            tx.transactionDate.month == m).toList();

        final mIncome = _getSumForPeriod(monthTxs, TransactionType.income) / 1000000.0;
        final mExpense = _getSumForPeriod(monthTxs, TransactionType.expense) / 1000000.0;

        currentBalance += (mIncome - mExpense);
        points.add(TrendPoint("T$m", currentBalance));
      }
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
        final q = ((now.month - 1) / 3).floor() + 1;
        return 'Quý $q/${now.year}';
      default:
        if (selectedFilter.startsWith('Năm')) {
          return selectedFilter;
        }
        return 'Năm $selectedYear';
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

    final isDataLoading = txProvider.isLoading && _allTransactions.isEmpty;

    return Scaffold(
      backgroundColor: isDark ? AppDesignTokens.darkBackground : AppColors.background,
      body: Column(
        children: [
          const ConnectionStatusBanner(),
          Expanded(
            child: isDataLoading
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
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width < 600
                      ? AppTheme.sp16
                      : AppTheme.sp24,
                  vertical: AppTheme.sp24,
                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;

    final textColor = isDark
        ? AppDesignTokens.darkTextPrimary
        : AppColors.foreground;

    final mutedTextColor = isDark
        ? AppDesignTokens.darkTextSecondary
        : AppColors.mutedFg;

    String getRoleName(String? roleId) {
      switch (roleId) {
        case 'admin':
          return 'Admin Hệ thống';
        case 'chiefAccountant':
          return 'Kế toán trưởng';
        case 'accountant':
          return 'Kế toán viên';
        case 'salesperson':
          return 'Nhân viên Bán hàng';
        case 'manager':
          return 'Quản lý';
        case 'partner':
          return 'Đối tác';
        default:
          return roleId ?? 'Người dùng';
      }
    }

    Widget buildRoleBadge() {
      if (user == null) {
        return const SizedBox.shrink();
      }

      return Container(
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppDesignTokens.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(
            AppDesignTokens.radiusMd,
          ),
          border: Border.all(
            color: AppDesignTokens.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 16,
              color: AppDesignTokens.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                getRoleName(user.roleId),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppDesignTokens.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNarrow) ...[
              Text(
                'Tổng quan',
                style: AppTextStyles.h1.copyWith(
                  color: textColor,
                ),
              ),
              const SizedBox(height: AppTheme.sp4),
              Text(
                '${_getCurrentDateRangeString()} - '
                    'cập nhật lúc ${_getLastUpdatedTimeString()}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: mutedTextColor,
                ),
              ),
              if (user != null) ...[
                const SizedBox(height: AppTheme.sp12),
                buildRoleBadge(),
              ],
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng quan',
                          style: AppTextStyles.h1.copyWith(
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.sp4),
                        Text(
                          '${_getCurrentDateRangeString()} - '
                              'cập nhật lúc ${_getLastUpdatedTimeString()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (user != null) ...[
                    const SizedBox(width: AppTheme.sp12),
                    buildRoleBadge(),
                  ],
                ],
              ),

            const SizedBox(height: AppTheme.sp24),
            _buildFilterChips(context),
          ],
        );
      },
    );
  }




  Future<void> _showYearPickerDialog(BuildContext context) async {
    final currentYear = DateTime.now().year;
    final availableYears = _allTransactions.map((tx) => tx.transactionDate.year).toSet();
    availableYears.add(currentYear);

    final years = availableYears.toList()..sort((a, b) => b.compareTo(a));

    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Chọn năm xem báo cáo'),
          children: years.map((y) {
            final isCur = y == selectedYear;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, y),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Năm $y', style: TextStyle(fontWeight: isCur ? FontWeight.bold : FontWeight.normal)),
                    if (isCur) const Icon(Icons.check, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedYear = picked;
        selectedFilter = 'Năm $picked';
        _processDataSync();
      });
    }
  }

  Widget _buildFilterChips(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? AppDesignTokens.darkSurface : AppColors.card;
    final chipBorder = isDark ? AppDesignTokens.darkBorder : AppColors.border;
    final unselectedText = isDark ? AppDesignTokens.darkTextSecondary : AppColors.mutedFg;

    final yearLabel = 'Năm $selectedYear';
    final filters = ['Tháng này', 'Tháng trước', 'Quý này', yearLabel];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter || (filter.startsWith('Năm') && selectedFilter.startsWith('Năm'));
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.sp8),
            child: InkWell(
              onTap: () {
                if (filter.startsWith('Năm')) {
                  _showYearPickerDialog(context);
                } else {
                  setState(() {
                    selectedFilter = filter;
                    _processDataSync();
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : chipBg,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? null : Border.all(color: chipBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter,
                      style: AppTextStyles.body.copyWith(
                        color: isSelected ? AppColors.primaryFg : unselectedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (filter.startsWith('Năm')) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: isSelected ? AppColors.primaryFg : unselectedText,
                      ),
                    ],
                  ],
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
    final chartTitle = (selectedFilter == 'Tháng này' || selectedFilter == 'Tháng trước')
        ? 'Thu & Chi theo tuần'
        : 'Thu & Chi theo tháng';

    return Container(
      decoration: _cardDecoration(context),
      padding: const EdgeInsets.all(AppTheme.sp24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: AppTheme.sp12,
            runSpacing: AppTheme.sp8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chartTitle, style: AppTextStyles.h2.copyWith(color: textColor)),
                  const SizedBox(height: AppTheme.sp4),
                  Text('Đơn vị: triệu VND', style: AppTextStyles.caption.copyWith(color: mutedTextColor)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: AppTheme.sp12,
            runSpacing: AppTheme.sp8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (selectedFilter == 'Tháng này' || selectedFilter == 'Tháng trước')
                        ? 'Xu hướng số dư ròng theo tuần'
                        : 'Xu hướng số dư ròng',
                    style: AppTextStyles.h2.copyWith(color: textColor),
                  ),
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
