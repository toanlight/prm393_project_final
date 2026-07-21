import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/services/rbac_permission_service.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid ?? 'mock-user-123';
    final roleId = authProvider.user?.roleId;
    context.read<TransactionProvider>().fetchTransactions(userId, roleId: roleId);
  }

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

  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required String amountText,
    required Color amountColor,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppDesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          border: Border.all(
            color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
          ),
          boxShadow: isDark ? AppDesignTokens.darkShadow : AppDesignTokens.lightShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppDesignTokens.darkTextSecondary
                    : AppDesignTokens.lightTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amountText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final searchField = TextField(
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
      decoration: InputDecoration(
        hintText: 'Tìm kiếm giao dịch...',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

    Widget buildFilterChip(String label, String value) {
      final isActive = _selectedType == value;
      return InkWell(
        onTap: () {
          setState(() {
            _selectedType = value;
          });
        },
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppDesignTokens.primary
                : (isDark ? AppDesignTokens.darkSurfaceCard : Colors.grey.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
            border: Border.all(
              color: isActive
                  ? AppDesignTokens.primary
                  : (isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? Colors.white
                  : (isDark ? AppDesignTokens.darkTextPrimary : AppDesignTokens.lightTextPrimary),
            ),
          ),
        ),
      );
    }

    final filterStatusButton = PopupMenuButton<String>(
      tooltip: 'Lọc trạng thái',
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_list,
            size: 20,
            color: _selectedStatus != 'all' ? AppDesignTokens.primary : null,
          ),
          const SizedBox(width: 4),
          Text(
            'Lọc',
            style: TextStyle(
              fontSize: 13,
              fontWeight: _selectedStatus != 'all' ? FontWeight.bold : FontWeight.normal,
              color: _selectedStatus != 'all' ? AppDesignTokens.primary : null,
            ),
          ),
        ],
      ),
      onSelected: (val) {
        setState(() {
          _selectedStatus = val;
        });
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
        PopupMenuItem(value: 'pending', child: Text('Chờ duyệt')),
        PopupMenuItem(value: 'confirmed', child: Text('Đã duyệt')),
        PopupMenuItem(value: 'rejected', child: Text('Từ chối')),
      ],
    );

    final user = context.watch<AuthProvider>().user;
    final canCreate = RbacPermissionService.canCreateTransaction(user);

    final addButton = canCreate
        ? ElevatedButton.icon(
            onPressed: () => context.push('/transactions/create'),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('Thêm mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesignTokens.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
              ),
            ),
          )
        : const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 768) {
          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              buildFilterChip('Tất cả', 'all'),
              const SizedBox(width: 6),
              buildFilterChip('Thu', 'income'),
              const SizedBox(width: 6),
              buildFilterChip('Chi', 'expense'),
              const SizedBox(width: 8),
              filterStatusButton,
              if (canCreate) ...[
                const SizedBox(width: 12),
                addButton,
              ],
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: searchField),
                  if (canCreate) ...[
                    const SizedBox(width: 8),
                    addButton,
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  buildFilterChip('Tất cả', 'all'),
                  const SizedBox(width: 6),
                  buildFilterChip('Thu', 'income'),
                  const SizedBox(width: 6),
                  buildFilterChip('Chi', 'expense'),
                  const Spacer(),
                  filterStatusButton,
                ],
              ),
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.user?.uid ?? 'mock-user-123';
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: Consumer<TransactionProvider>(
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

            // Tính toán tổng quan thu/chi và số dư (Chỉ tính các giao dịch đã được phê duyệt 'confirmed')
            int totalIncome = 0;
            int totalExpense = 0;
            for (var tx in provider.transactions) {
              if (tx.status == 'confirmed') {
                if (tx.type == TransactionType.income) {
                  totalIncome += tx.amountVnd;
                } else {
                  totalExpense += tx.amountVnd;
                }
              }
            }
            final balance = totalIncome - totalExpense;

            final filteredTxs = _getFilteredTransactions(provider.transactions);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tiêu đề chính + Subtitle
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDesignTokens.spaceMd,
                    AppDesignTokens.spaceSm,
                    AppDesignTokens.spaceMd,
                    2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lịch sử giao dịch',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                          ),
                          Text(
                            '${provider.transactions.length} giao dịch · Tháng ${now.month}/${now.year}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppDesignTokens.darkTextSecondary
                                  : AppDesignTokens.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Khối tóm tắt (3 thẻ bo góc nằm ngang)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignTokens.spaceMd,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      _buildSummaryCard(
                        context: context,
                        title: 'Tổng Thu',
                        amountText: '+${_formatVnd(totalIncome)}',
                        amountColor: AppDesignTokens.success,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 6),
                      _buildSummaryCard(
                        context: context,
                        title: 'Tổng Chi',
                        amountText: '-${_formatVnd(totalExpense)}',
                        amountColor: AppDesignTokens.error,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 6),
                      _buildSummaryCard(
                        context: context,
                        title: 'Số dư cuối',
                        amountText: _formatVnd(balance),
                        amountColor: AppDesignTokens.primary,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // 3. Thanh công cụ tìm kiếm & bộ lọc
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignTokens.spaceMd,
                    vertical: 2,
                  ),
                  child: _buildFilterBar(context),
                ),

                const SizedBox(height: AppDesignTokens.spaceSm),

                // 4. Bảng danh sách giao dịch (Responsive Layout)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignTokens.spaceLg,
                    ),
                    child: provider.transactions.isEmpty
                        ? TransactionEmptyState(onRefresh: _loadData)
                        : (filteredTxs.isEmpty
                            ? const Center(
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
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth >= 900) {
                                    return TransactionListDesktop(
                                      transactions: filteredTxs,
                                      onDelete: (id) => provider.deleteTransaction(id, userId),
                                    );
                                  } else {
                                    return TransactionListMobile(
                                      transactions: filteredTxs,
                                      onDelete: (id) => provider.deleteTransaction(id, userId),
                                    );
                                  }
                                },
                              )),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
