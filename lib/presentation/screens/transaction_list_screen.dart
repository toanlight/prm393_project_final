import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
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
  String _selectedType = 'all'; // 'all', 'income', 'expense'
  String _selectedStatus = 'all'; // 'all', 'pending', 'confirmed', 'rejected'
  String _searchQuery = '';

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> txs) {
    return txs.where((tx) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesNote = tx.note.toLowerCase().contains(query);
        final matchesCategory = tx.category.toLowerCase().contains(query);
        if (!matchesNote && !matchesCategory) return false;
      }
      if (_selectedType != 'all') {
        if (_selectedType == 'income' && tx.type != TransactionType.income) return false;
        if (_selectedType == 'expense' && tx.type != TransactionType.expense) return false;
      }
      if (_selectedStatus != 'all') {
        if (tx.status != _selectedStatus) return false;
      }
      return true;
    }).toList();
  }

  Widget _buildFilterBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Search input
    final searchField = TextField(
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
      decoration: InputDecoration(
        hintText: 'Tìm ghi chú, danh mục...',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
          ),
        ),
      ),
    );

    // Type filter dropdown
    final typeDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        border: Border.all(
          color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isDense: true,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Tất cả loại')),
            DropdownMenuItem(value: 'income', child: Text('Thu nhập')),
            DropdownMenuItem(value: 'expense', child: Text('Chi tiêu')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedType = val;
              });
            }
          },
        ),
      ),
    );

    // Status filter dropdown
    final statusDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        border: Border.all(
          color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          isDense: true,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
            DropdownMenuItem(value: 'pending', child: Text('Chờ duyệt')),
            DropdownMenuItem(value: 'confirmed', child: Text('Đã duyệt')),
            DropdownMenuItem(value: 'rejected', child: Text('Từ chối')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedStatus = val;
              });
            }
          },
        ),
      ),
    );

    // Responsive filter layout
    return AppResponsiveLayout(
      mobile: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: typeDropdown),
              const SizedBox(width: 8),
              Expanded(child: statusDropdown),
            ],
          ),
        ],
      ),
      tablet: Row(
        children: [
          Expanded(flex: 2, child: searchField),
          const SizedBox(width: 12),
          Expanded(child: typeDropdown),
          const SizedBox(width: 12),
          Expanded(child: statusDropdown),
        ],
      ),
      desktop: Row(
        children: [
          Expanded(flex: 3, child: searchField),
          const SizedBox(width: 16),
          SizedBox(width: 160, child: typeDropdown),
          const SizedBox(width: 16),
          SizedBox(width: 180, child: statusDropdown),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    // ==========================================
    // [DEV-3 MOCK DATA] - CẦN THAY THẾ KHI TÍCH HỢP FIREBASE
    // Chức năng: Lấy ID người dùng (hiện tại fallback về mock-user-123)
    // ==========================================
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
    // ==========================================
    // [DEV-3 MOCK DATA] - CẦN THAY THẾ KHI TÍCH HỢP FIREBASE
    // Chức năng: ID người dùng giả lập cho Consumer
    // ==========================================
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'create_transaction',
        onPressed: () => context.push('/transactions/create'),
        tooltip: 'Thêm giao dịch',
        child: const Icon(Icons.add),
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
            if (tx.type == TransactionType.income) {
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

              // Bộ lọc giao dịch
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsiveValue(
                    mobile: AppDesignTokens.spaceMd,
                    tablet: AppDesignTokens.spaceLg,
                    desktop: AppDesignTokens.spaceXl,
                  ),
                ),
                child: _buildFilterBar(context),
              ),
              const SizedBox(height: AppDesignTokens.spaceMd),

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
                  child: Builder(
                    builder: (context) {
                      final filteredTxs = _getFilteredTransactions(provider.transactions);
                      if (filteredTxs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppDesignTokens.spaceLg),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.filter_list_off, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Không tìm thấy giao dịch phù hợp với bộ lọc.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return AppResponsiveLayout(
                        mobile: TransactionListMobile(
                          transactions: filteredTxs,
                          onDelete: (id) => provider.deleteTransaction(id, userId),
                        ),
                        tablet: TransactionListDesktop(
                          transactions: filteredTxs,
                          onDelete: (id) => provider.deleteTransaction(id, userId),
                        ),
                        desktop: TransactionListDesktop(
                          transactions: filteredTxs,
                          onDelete: (id) => provider.deleteTransaction(id, userId),
                        ),
                      );
                    },
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
