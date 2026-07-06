import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_empty_state.dart';
import '../widgets/transaction_list_mobile.dart';
import '../widgets/transaction_list_desktop.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid ?? 'mock-user-123';
    context.read<TransactionProvider>().fetchTransactions(userId);
  }

  String _formatVnd(int amount) {
    final cleanString = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = cleanString.length - 1; i >= 0; i--) {
      buffer.write(cleanString[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join('')} đ';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.user?.uid ?? 'mock-user-123';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách giao dịch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppDesignTokens.primary),
            );
          }

          if (provider.isError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDesignTokens.spaceLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppDesignTokens.error,
                      size: 64,
                    ),
                    const SizedBox(height: AppDesignTokens.spaceMd),
                    Text(
                      'Đã xảy ra lỗi!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppDesignTokens.spaceSm),
                    Text(
                      provider.errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? AppDesignTokens.darkTextSecondary
                            : AppDesignTokens.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.spaceLg),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.transactions.isEmpty) {
            return TransactionEmptyState(onRefresh: _loadData);
          }

          // Tính toán tổng quan thu/chi
          int totalIncome = 0;
          int totalExpense = 0;
          for (var tx in provider.transactions) {
            if (tx.type == 'thu') {
              totalIncome += tx.amountVnd;
            } else {
              totalExpense += tx.amountVnd;
            }
          }
          final balance = totalIncome - totalExpense;

          return Column(
            children: [
              // Thống kê nhanh trên cùng
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsiveValue(
                    mobile: AppDesignTokens.spaceMd,
                    tablet: AppDesignTokens.spaceLg,
                    desktop: AppDesignTokens.spaceXl,
                  ),
                  vertical: AppDesignTokens.spaceMd,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
                  decoration: BoxDecoration(
                    color: isDark ? AppDesignTokens.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
                    border: Border.all(
                      color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
                    ),
                    boxShadow: isDark ? AppDesignTokens.darkShadow : AppDesignTokens.lightShadow,
                  ),
                  child: AppResponsiveLayout(
                    mobile: Column(
                      children: [
                        _buildSummaryItem(
                          context: context,
                          title: 'Số dư hiện tại',
                          value: _formatVnd(balance),
                          icon: Icons.account_balance_wallet_rounded,
                          color: balance >= 0 ? AppDesignTokens.primary : AppDesignTokens.error,
                        ),
                        const Divider(height: AppDesignTokens.spaceMd),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryItem(
                                context: context,
                                title: 'Tổng thu',
                                value: _formatVnd(totalIncome),
                                icon: Icons.arrow_downward_rounded,
                                color: AppDesignTokens.success,
                                small: true,
                              ),
                            ),
                            Container(width: 1, height: 40, color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder),
                            Expanded(
                              child: _buildSummaryItem(
                                context: context,
                                title: 'Tổng chi',
                                value: _formatVnd(totalExpense),
                                icon: Icons.arrow_upward_rounded,
                                color: AppDesignTokens.error,
                                small: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    desktop: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            context: context,
                            title: 'Số dư hiện tại',
                            value: _formatVnd(balance),
                            icon: Icons.account_balance_wallet_rounded,
                            color: balance >= 0 ? AppDesignTokens.primary : AppDesignTokens.error,
                          ),
                        ),
                        Container(width: 1, height: 50, color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder),
                        Expanded(
                          child: _buildSummaryItem(
                            context: context,
                            title: 'Tổng thu nhập',
                            value: _formatVnd(totalIncome),
                            icon: Icons.arrow_downward_rounded,
                            color: AppDesignTokens.success,
                          ),
                        ),
                        Container(width: 1, height: 50, color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder),
                        Expanded(
                          child: _buildSummaryItem(
                            context: context,
                            title: 'Tổng chi tiêu',
                            value: _formatVnd(totalExpense),
                            icon: Icons.arrow_upward_rounded,
                            color: AppDesignTokens.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Danh sách / Bảng giao dịch
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsiveValue(
                      mobile: 0,
                      tablet: AppDesignTokens.spaceLg,
                      desktop: AppDesignTokens.spaceXl,
                    ),
                  ),
                  child: AppResponsiveLayout(
                    mobile: TransactionListMobile(
                      transactions: provider.transactions,
                      onDelete: (id) => provider.deleteTransaction(id, userId),
                    ),
                    tablet: TransactionListDesktop(
                      transactions: provider.transactions,
                      onDelete: (id) => provider.deleteTransaction(id, userId),
                    ),
                    desktop: TransactionListDesktop(
                      transactions: provider.transactions,
                      onDelete: (id) => provider.deleteTransaction(id, userId),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool small = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(small ? AppDesignTokens.spaceXs : AppDesignTokens.spaceSm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: small ? 18 : 24),
        ),
        const SizedBox(width: AppDesignTokens.spaceSm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: small ? 11 : 12,
                color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: small ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppDesignTokens.darkTextPrimary : AppDesignTokens.lightTextPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
