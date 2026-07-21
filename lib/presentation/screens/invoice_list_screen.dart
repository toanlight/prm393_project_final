import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../../domain/services/rbac_permission_service.dart';
import '../providers/auth_provider.dart';
import '../providers/invoice_provider.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() =>
      _InvoiceListScreenState();
}

class _InvoiceListScreenState
    extends State<InvoiceListScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  String? _loadedUserId;

  static const int _itemsPerPage = 10;
  int _currentPage = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      debugPrint(
        '[InvoiceListScreen] Chưa có Firebase user, '
            'không tải danh sách hóa đơn',
      );
      return;
    }

    debugPrint(
      '[InvoiceListScreen] Tải hóa đơn cho uid=${user.uid}',
    );

    await context
        .read<InvoiceProvider>()
        .loadInvoices(
      user.uid,
      roleId: user.roleId,
      taxCode: user.taxCode,
    );
  }

  Future<void> _openScanner() async {
    final user = context.read<AuthProvider>().user;
    if (!RbacPermissionService.canCreateInvoice(user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tài khoản của bạn không có quyền quét/tạo hóa đơn.'),
          backgroundColor: AppDesignTokens.error,
        ),
      );
      return;
    }

    final created = await context.push<bool>(
      '/invoices/scan',
    );

    if (!mounted || created != true) {
      return;
    }

    await _loadData();
  }

  void _scheduleInvoiceLoadForUser(
      String? currentUserId,
      ) {
    if (currentUserId == null ||
        currentUserId.isEmpty ||
        currentUserId == _loadedUserId) {
      return;
    }

    _loadedUserId = currentUserId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      debugPrint(
        '[InvoiceListScreen] Auth đã sẵn sàng, '
            'tự tải invoice cho uid=$currentUserId',
      );

      final currentUser = context.read<AuthProvider>().user;
      context
          .read<InvoiceProvider>()
          .loadInvoices(
            currentUserId,
            roleId: currentUser?.roleId,
            taxCode: currentUser?.taxCode,
          );
    });
  }


  Widget _buildPagination({
    required int totalItems,
    required bool isDark,
  }) {
    final totalPages = (totalItems / _itemsPerPage).ceil();

    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final startItem = ((_currentPage - 1) * _itemsPerPage) + 1;
    final endItem = (_currentPage * _itemsPerPage).clamp(0, totalItems);

    return Padding(
      padding: const EdgeInsets.only(
        top: AppDesignTokens.spaceMd,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Hiển thị $startItem–$endItem trên $totalItems hóa đơn',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppDesignTokens.darkTextSecondary
                    : AppDesignTokens.lightTextSecondary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Trang trước',
            onPressed: _currentPage > 1
                ? () {
              setState(() {
                _currentPage--;
              });
            }
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 74),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppDesignTokens.darkSurfaceCard
                  : Colors.white,
              borderRadius: BorderRadius.circular(
                AppDesignTokens.radiusSm,
              ),
              border: Border.all(
                color: isDark
                    ? AppDesignTokens.darkBorder
                    : AppDesignTokens.lightBorder,
              ),
            ),
            child: Text(
              '$_currentPage/$totalPages',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Trang sau',
            onPressed: _currentPage < totalPages
                ? () {
              setState(() {
                _currentPage++;
              });
            }
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final currentUserId = user?.uid;
    final canCreate = RbacPermissionService.canCreateInvoice(user);

    _scheduleInvoiceLoadForUser(currentUserId);

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: (context.isDesktop || !canCreate)
          ? null
          : FloatingActionButton.extended(
        heroTag: 'invoice_smart_scan',
        onPressed: _openScanner,
        icon: const Icon(
          Icons.document_scanner_outlined,
        ),
        label: const Text('Smart Scan'),
      ),
      body: SafeArea(
        child: Consumer<InvoiceProvider>(
          builder: (context, provider, _) {
            if (authProvider.isLoading &&
                authProvider.user == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (authProvider.user == null) {
              return const _AuthenticationRequiredState();
            }

            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (provider.isError) {
              return _InvoiceErrorState(
                message: provider.errorMessage,
                onRetry: _loadData,
              );
            }

            // Lọc danh sách hóa đơn hiển thị theo vai trò người dùng (Partner chỉ thấy hóa đơn trùng MST)
            final visibleInvoices = RbacPermissionService.filterVisibleInvoices(
              user,
              provider.filteredItems.map((e) => e.invoice).toList(),
            );
            final visibleSet = visibleInvoices.map((i) => i.invoiceId).toSet();
            final visibleItems = provider.filteredItems
                .where(
                  (entry) =>
                  visibleSet.contains(entry.invoice.invoiceId),
            )
                .toList();

            final totalPages =
            (visibleItems.length / _itemsPerPage).ceil();

            if (totalPages > 0 && _currentPage > totalPages) {
              _currentPage = totalPages;
            }

            final startIndex =
                (_currentPage - 1) * _itemsPerPage;

            final pagedItems = visibleItems
                .skip(startIndex)
                .take(_itemsPerPage)
                .toList(growable: false);

            return RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  context.responsiveValue(
                    mobile: AppDesignTokens.spaceMd,
                    tablet: AppDesignTokens.spaceLg,
                    desktop: AppDesignTokens.spaceXl,
                  ),
                  AppDesignTokens.spaceMd,
                  context.responsiveValue(
                    mobile: AppDesignTokens.spaceMd,
                    tablet: AppDesignTokens.spaceLg,
                    desktop: AppDesignTokens.spaceXl,
                  ),
                  context.isDesktop
                      ? AppDesignTokens.spaceXl
                      : 96,
                ),
                children: [
                  _buildHeader(context, canCreate),
                  const SizedBox(
                    height: AppDesignTokens.spaceSm,
                  ),
                  _InvoiceSummarySection(
                    provider: provider,
                  ),
                  const SizedBox(
                    height: AppDesignTokens.spaceSm,
                  ),
                  _buildToolbar(
                    context,
                    provider,
                    isDark,
                    visibleItems.length,
                  ),
                  const SizedBox(
                    height: AppDesignTokens.spaceSm,
                  ),
                  if (visibleItems.isEmpty)
                    _InvoiceEmptyState(
                      hasFilters:
                      provider.searchQuery.isNotEmpty ||
                          provider.statusFilter != 'all',
                      onClearFilters: () {
                        _searchController.clear();
                        provider.clearFilters();
                        setState(() {
                          _currentPage = 1;
                        });
                      },
                      onScan: canCreate ? () => _openScanner() : null,
                    )
                  else
                    AppResponsiveLayout(
                      mobile: _InvoiceMobileList(
                        items: pagedItems,
                      ),
                      tablet: _InvoiceDesktopTable(
                        items: pagedItems,
                      ),
                      desktop: _InvoiceDesktopTable(
                        items: pagedItems,
                      ),
                    ),
                  if (visibleItems.isNotEmpty)
                    _buildPagination(
                      totalItems: visibleItems.length,
                      isDark: isDark,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool canCreate) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Quản lý hóa đơn',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tra cứu, kiểm tra và mở chi tiết '
                    'các hóa đơn đã quét.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              ),
            ],
          ),
        ),
        if (context.isDesktop && canCreate)
          FilledButton.icon(
            onPressed: _openScanner,
            icon: const Icon(
              Icons.document_scanner_outlined,
            ),
            label: const Text('Smart Scan'),
          ),
      ],
    );
  }

  Widget _buildToolbar(
      BuildContext context,
      InvoiceProvider provider,
      bool isDark,
      int itemCount,
      ) {
    return Container(
      padding: const EdgeInsets.all(
        AppDesignTokens.spaceMd,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppDesignTokens.darkSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(
          AppDesignTokens.radiusLg,
        ),
        border: Border.all(
          color: isDark
              ? AppDesignTokens.darkBorder
              : AppDesignTokens.lightBorder,
        ),
      ),
      child: Wrap(
        spacing: AppDesignTokens.spaceMd,
        runSpacing: AppDesignTokens.spaceSm,
        crossAxisAlignment:
        WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: context.isDesktop
                ? 360
                : double.infinity,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                provider.setSearchQuery(value);
                setState(() {
                  _currentPage = 1;
                });
              },
              decoration: InputDecoration(
                hintText:
                'Tìm theo số hóa đơn, đơn vị bán, MST...',
                prefixIcon:
                const Icon(Icons.search_rounded),
                suffixIcon:
                provider.searchQuery.isEmpty
                    ? null
                    : IconButton(
                  tooltip: 'Xóa tìm kiếm',
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery('');
                    setState(() {
                      _currentPage = 1;
                    });
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: context.isDesktop
                ? 210
                : double.infinity,
            child:
            DropdownButtonFormField<String>(
              value: provider.statusFilter,
              decoration: const InputDecoration(
                labelText: 'Trạng thái',
                prefixIcon: Icon(
                  Icons.filter_alt_outlined,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('Tất cả'),
                ),
                DropdownMenuItem(
                  value: 'confirmed',
                  child: Text('Đã xác nhận'),
                ),
                DropdownMenuItem(
                  value: 'draft',
                  child: Text('Bản nháp'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  provider.setStatusFilter(value);
                  setState(() {
                    _currentPage = 1;
                  });
                }
              },
            ),
          ),
          Text(
            '$itemCount hóa đơn',
          ),
        ],
      ),
    );
  }
}

class _InvoiceSummarySection
    extends StatelessWidget {
  final InvoiceProvider provider;

  const _InvoiceSummarySection({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _InvoiceSummaryData(
        title: 'Tổng hóa đơn',
        value: provider.totalCount.toString(),
        icon: Icons.receipt_long_outlined,
        color: AppDesignTokens.primary,
      ),
      _InvoiceSummaryData(
        title: 'Đã xác nhận',
        value: provider.confirmedCount.toString(),
        icon: Icons.verified_outlined,
        color: AppDesignTokens.success,
      ),
      _InvoiceSummaryData(
        title: 'Bản nháp',
        value: provider.draftCount.toString(),
        icon: Icons.edit_note_outlined,
        color: AppDesignTokens.warning,
      ),
      _InvoiceSummaryData(
        title: 'Tổng giá trị',
        value: _formatMoney(
          provider.totalAmount,
        ),
        icon: Icons.payments_outlined,
        color: AppDesignTokens.secondary,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate:
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
        context.valueForDeviceType(
          mobile: 2,
          tablet: 2,
          desktop: 4,
        ),
        crossAxisSpacing: AppDesignTokens.spaceSm,
        mainAxisSpacing: AppDesignTokens.spaceSm,
        mainAxisExtent: context.valueForDeviceType<double?>(
          mobile: 68,
          tablet: 72,
          desktop: null,
        ),
        childAspectRatio: context.isDesktop ? 2.15 : 1.0,
      ),
      itemBuilder: (context, index) {
        return _InvoiceSummaryCard(
          data: cards[index],
        );
      },
    );
  }
}

class _InvoiceSummaryData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InvoiceSummaryData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _InvoiceSummaryCard extends StatelessWidget {
  final _InvoiceSummaryData data;

  const _InvoiceSummaryCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppDesignTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        border: Border.all(
          color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
        ),
        boxShadow: isDark ? AppDesignTokens.darkShadow : AppDesignTokens.lightShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
            ),
            child: Icon(
              data.icon,
              color: data.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: data.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceDesktopTable
    extends StatelessWidget {
  final List<InvoiceListEntry> items;

  const _InvoiceDesktopTable({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? AppDesignTokens.darkSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(
          AppDesignTokens.radiusLg,
        ),
        border: Border.all(
          color: isDark
              ? AppDesignTokens.darkBorder
              : AppDesignTokens.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth:
                constraints.maxWidth,
              ),
              child: DataTable(
                headingRowColor:
                WidgetStatePropertyAll(
                  isDark
                      ? AppDesignTokens
                      .darkSurfaceCard
                      : AppDesignTokens
                      .lightSurfaceCard,
                ),
                columns: const [
                  DataColumn(
                    label: Text('Số hóa đơn'),
                  ),
                  DataColumn(
                    label: Text('Đơn vị bán'),
                  ),
                  DataColumn(
                    label: Text('Ngày hóa đơn'),
                  ),
                  DataColumn(
                    label: Text('Tổng tiền'),
                  ),
                  DataColumn(
                    label: Text('Trạng thái'),
                  ),
                  DataColumn(
                    label: Text('Thao tác'),
                  ),
                ],
                rows: items.map((entry) {
                  final invoice =
                      entry.invoice;

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          invoice.invoiceNumber ??
                              '—',
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 260,
                          child: Text(
                            invoice.partnerName ??
                                '—',
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatDate(
                            invoice.invoiceDate,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatMoney(
                            invoice.totalAmount,
                          ),
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        _InvoiceStatusBadge(
                          status:
                          invoice.status,
                        ),
                      ),
                      DataCell(
                        IconButton(
                          tooltip:
                          'Xem chi tiết',
                          onPressed: () {
                            context.push(
                              '/invoices/receipt',
                              extra:
                              entry.transaction,
                            );
                          },
                          icon: const Icon(
                            Icons
                                .visibility_outlined,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(growable: false),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceMobileList
    extends StatelessWidget {
  final List<InvoiceListEntry> items;

  const _InvoiceMobileList({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((entry) {
        final invoice = entry.invoice;

        return Padding(
          padding: const EdgeInsets.only(
            bottom: AppDesignTokens.spaceSm,
          ),
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(
                AppDesignTokens.radiusMd,
              ),
              onTap: () {
                context.push(
                  '/invoices/receipt',
                  extra: entry.transaction,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(
                  AppDesignTokens.spaceMd,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding:
                          const EdgeInsets.all(
                            AppDesignTokens
                                .spaceSm,
                          ),
                          decoration:
                          BoxDecoration(
                            color: AppDesignTokens
                                .primary
                                .withOpacity(0.1),
                            borderRadius:
                            BorderRadius.circular(
                              AppDesignTokens
                                  .radiusSm,
                            ),
                          ),
                          child: const Icon(
                            Icons
                                .receipt_long_outlined,
                            color:
                            AppDesignTokens
                                .primary,
                          ),
                        ),
                        const SizedBox(
                          width: AppDesignTokens
                              .spaceMd,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                invoice.partnerName ??
                                    'Không rõ đơn vị bán',
                                maxLines: 2,
                                overflow:
                                TextOverflow
                                    .ellipsis,
                                style:
                                const TextStyle(
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                invoice.invoiceNumber ??
                                    'Chưa có số hóa đơn',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _InvoiceStatusBadge(
                          status: invoice.status,
                        ),
                      ],
                    ),
                    const Divider(
                      height:
                      AppDesignTokens.spaceLg,
                    ),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                      children: [
                        Text(
                          _formatDate(
                            invoice.invoiceDate,
                          ),
                        ),
                        Text(
                          _formatMoney(
                            invoice.totalAmount,
                          ),
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _InvoiceStatusBadge
    extends StatelessWidget {
  final String status;

  const _InvoiceStatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized =
    status.toLowerCase();

    final isConfirmed =
        normalized == 'confirmed';

    final color = isConfirmed
        ? AppDesignTokens.success
        : AppDesignTokens.warning;

    final label = isConfirmed
        ? 'Đã xác nhận'
        : 'Bản nháp';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          AppDesignTokens.radiusXl,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InvoiceEmptyState
    extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;
  final VoidCallback? onScan;

  const _InvoiceEmptyState({
    required this.hasFilters,
    required this.onClearFilters,
    this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final showAction = hasFilters || onScan != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 64,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'Không tìm thấy hóa đơn phù hợp'
                : 'Chưa có hóa đơn',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Thử thay đổi từ khóa hoặc bộ lọc trạng thái.'
                : 'Các hóa đơn được tạo sẽ hiển thị tại đây.',
            textAlign: TextAlign.center,
          ),
          if (showAction) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: hasFilters
                  ? onClearFilters
                  : onScan,
              icon: Icon(
                hasFilters
                    ? Icons
                    .filter_alt_off_outlined
                    : Icons
                    .document_scanner_outlined,
              ),
              label: Text(
                hasFilters
                    ? 'Xóa bộ lọc'
                    : 'Smart Scan',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InvoiceErrorState
    extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _InvoiceErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthenticationRequiredState
    extends StatelessWidget {
  const _AuthenticationRequiredState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn cần đăng nhập để xem hóa đơn.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(int value) {
  return '${NumberFormat.decimalPattern('vi_VN').format(value)} đ';
}

String _formatDate(DateTime? value) {
  if (value == null) {
    return '—';
  }

  return DateFormat('dd/MM/yyyy').format(value);
}