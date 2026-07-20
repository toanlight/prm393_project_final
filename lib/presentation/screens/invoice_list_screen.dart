import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../providers/auth_provider.dart';
import '../providers/invoice_provider.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().user?.uid ?? 'mock-user-123';
    await context.read<InvoiceProvider>().loadInvoices(userId);
  }

  Future<void> _openScanner() async {
    final created = await context.push<bool>('/invoices/scan');
    if (!mounted || created != true) return;
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: context.isDesktop
          ? null
          : FloatingActionButton.extended(
        heroTag: 'invoice_smart_scan',
        onPressed: _openScanner,
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('Smart Scan'),
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.isError) {
            return _InvoiceErrorState(
              message: provider.errorMessage,
              onRetry: _loadData,
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
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
                context.isDesktop ? AppDesignTokens.spaceXl : 96,
              ),
              children: [
                _buildHeader(context),
                const SizedBox(height: AppDesignTokens.spaceLg),
                _InvoiceSummarySection(provider: provider),
                const SizedBox(height: AppDesignTokens.spaceLg),
                _buildToolbar(context, provider, isDark),
                const SizedBox(height: AppDesignTokens.spaceMd),
                if (provider.filteredItems.isEmpty)
                  _InvoiceEmptyState(
                    hasFilters: provider.searchQuery.isNotEmpty ||
                        provider.statusFilter != 'all',
                    onClearFilters: () {
                      _searchController.clear();
                      provider.clearFilters();
                    },
                    onScan: _openScanner,
                  )
                else
                  AppResponsiveLayout(
                    mobile: _InvoiceMobileList(items: provider.filteredItems),
                    tablet: _InvoiceDesktopTable(items: provider.filteredItems),
                    desktop: _InvoiceDesktopTable(items: provider.filteredItems),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quản lý hóa đơn',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tra cứu, kiểm tra và mở chi tiết các hóa đơn đã quét.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (context.isDesktop)
          FilledButton.icon(
            onPressed: _openScanner,
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Smart Scan'),
          ),
      ],
    );
  }

  Widget _buildToolbar(
      BuildContext context,
      InvoiceProvider provider,
      bool isDark,
      ) {
    return Container(
      padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: isDark ? AppDesignTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
        border: Border.all(
          color: isDark
              ? AppDesignTokens.darkBorder
              : AppDesignTokens.lightBorder,
        ),
      ),
      child: Wrap(
        spacing: AppDesignTokens.spaceMd,
        runSpacing: AppDesignTokens.spaceSm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: context.isDesktop ? 360 : double.infinity,
            child: TextField(
              controller: _searchController,
              onChanged: provider.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Tìm theo số hóa đơn, đơn vị bán, MST...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: provider.searchQuery.isEmpty
                    ? null
                    : IconButton(
                  tooltip: 'Xóa tìm kiếm',
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ),
          SizedBox(
            width: context.isDesktop ? 210 : double.infinity,
            child: DropdownButtonFormField<String>(
              value: provider.statusFilter,
              decoration: const InputDecoration(
                labelText: 'Trạng thái',
                prefixIcon: Icon(Icons.filter_alt_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                DropdownMenuItem(
                  value: 'confirmed',
                  child: Text('Đã xác nhận'),
                ),
                DropdownMenuItem(value: 'draft', child: Text('Bản nháp')),
              ],
              onChanged: (value) {
                if (value != null) provider.setStatusFilter(value);
              },
            ),
          ),
          Text('${provider.filteredItems.length} hóa đơn'),
        ],
      ),
    );
  }
}

class _InvoiceSummarySection extends StatelessWidget {
  final InvoiceProvider provider;

  const _InvoiceSummarySection({required this.provider});

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
        value: _formatMoney(provider.totalAmount),
        icon: Icons.payments_outlined,
        color: AppDesignTokens.secondary,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.valueForDeviceType(
          mobile: 2,
          tablet: 2,
          desktop: 4,
        ),
        crossAxisSpacing: AppDesignTokens.spaceMd,
        mainAxisSpacing: AppDesignTokens.spaceMd,
        childAspectRatio: context.isDesktop ? 2.15 : 1.65,
      ),
      itemBuilder: (context, index) => _InvoiceSummaryCard(data: cards[index]),
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

  const _InvoiceSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: isDark ? AppDesignTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
        border: Border.all(
          color: isDark
              ? AppDesignTokens.darkBorder
              : AppDesignTokens.lightBorder,
        ),
        boxShadow:
        isDark ? AppDesignTokens.darkShadow : AppDesignTokens.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesignTokens.spaceSm),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                data.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceDesktopTable extends StatelessWidget {
  final List<InvoiceListEntry> items;

  const _InvoiceDesktopTable({required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppDesignTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
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
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  isDark
                      ? AppDesignTokens.darkSurfaceCard
                      : AppDesignTokens.lightSurfaceCard,
                ),
                columns: const [
                  DataColumn(label: Text('Số hóa đơn')),
                  DataColumn(label: Expanded(child: Text('Đơn vị bán'))),
                  DataColumn(label: Text('Ngày hóa đơn')),
                  DataColumn(label: Text('Tổng tiền')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('Thao tác')),
                ],
                rows: items.map((entry) {
                  final invoice = entry.invoice;
                  return DataRow(
                    cells: [
                      DataCell(Text(invoice.invoiceNumber ?? '—')),
                      DataCell(
                        Text(
                          invoice.partnerName ?? '—',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DataCell(Text(_formatDate(invoice.invoiceDate))),
                      DataCell(
                        Text(
                          _formatMoney(invoice.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(_InvoiceStatusBadge(status: invoice.status)),
                      DataCell(
                        IconButton(
                          tooltip: 'Xem chi tiết',
                          onPressed: () => context.push(
                            '/invoices/receipt',
                            extra: entry.transaction,
                          ),
                          icon: const Icon(Icons.visibility_outlined),
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
class _InvoiceMobileList extends StatelessWidget {
  final List<InvoiceListEntry> items;

  const _InvoiceMobileList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((entry) {
        final invoice = entry.invoice;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDesignTokens.spaceSm),
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
              onTap: () => context.push(
                '/invoices/receipt',
                extra: entry.transaction,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppDesignTokens.spaceSm),
                          decoration: BoxDecoration(
                            color: AppDesignTokens.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusSm,
                            ),
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: AppDesignTokens.primary,
                          ),
                        ),
                        const SizedBox(width: AppDesignTokens.spaceMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.partnerName ?? 'Không rõ đơn vị bán',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(invoice.invoiceNumber ?? 'Chưa có số hóa đơn'),
                            ],
                          ),
                        ),
                        _InvoiceStatusBadge(status: invoice.status),
                      ],
                    ),
                    const Divider(height: AppDesignTokens.spaceLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDate(invoice.invoiceDate)),
                        Text(
                          _formatMoney(invoice.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
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

class _InvoiceStatusBadge extends StatelessWidget {
  final String status;

  const _InvoiceStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isConfirmed = normalized == 'confirmed';
    final color = isConfirmed ? AppDesignTokens.success : AppDesignTokens.warning;
    final label = isConfirmed ? 'Đã xác nhận' : 'Bản nháp';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusXl),
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

class _InvoiceEmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onScan;

  const _InvoiceEmptyState({
    required this.hasFilters,
    required this.onClearFilters,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 72),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'Không tìm thấy hóa đơn phù hợp' : 'Chưa có hóa đơn',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Thử thay đổi từ khóa hoặc bộ lọc trạng thái.'
                : 'Quét hóa đơn đầu tiên để hệ thống tự tạo hóa đơn và giao dịch.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: hasFilters ? onClearFilters : onScan,
            icon: Icon(
              hasFilters
                  ? Icons.filter_alt_off_outlined
                  : Icons.document_scanner_outlined,
            ),
            label: Text(hasFilters ? 'Xóa bộ lọc' : 'Smart Scan'),
          ),
        ],
      ),
    );
  }
}

class _InvoiceErrorState extends StatelessWidget {
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
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(int value) =>
    '${NumberFormat.decimalPattern('vi_VN').format(value)} đ';

String _formatDate(DateTime? value) =>
    value == null ? '—' : DateFormat('dd/MM/yyyy').format(value);
