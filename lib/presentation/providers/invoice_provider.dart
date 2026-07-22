import 'package:flutter/foundation.dart';

import '../../domain/models/invoice_model.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/repositories/transaction_repository.dart';

class InvoiceListEntry {
  final InvoiceModel invoice;
  final TransactionModel transaction;

  const InvoiceListEntry({
    required this.invoice,
    required this.transaction,
  });
}

enum InvoiceLoadStatus {
  initial,
  loading,
  success,
  error,
}

class InvoiceProvider extends ChangeNotifier {
  final InvoiceRepository _invoiceRepository;
  final TransactionRepository _transactionRepository;

  InvoiceProvider({
    required InvoiceRepository invoiceRepository,
    required TransactionRepository transactionRepository,
  })  : _invoiceRepository = invoiceRepository,
        _transactionRepository = transactionRepository;

  InvoiceLoadStatus _status = InvoiceLoadStatus.initial;
  List<InvoiceListEntry> _items = const [];
  String _errorMessage = '';
  String _searchQuery = '';
  String _statusFilter = 'all';

  InvoiceLoadStatus get status => _status;

  bool get isLoading =>
      _status == InvoiceLoadStatus.loading;

  bool get isError =>
      _status == InvoiceLoadStatus.error;

  bool get isSuccess =>
      _status == InvoiceLoadStatus.success;

  String get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;

  String get statusFilter => _statusFilter;

  List<InvoiceListEntry> get items =>
      List.unmodifiable(_items);

  List<InvoiceListEntry> get filteredItems {
    final query = _searchQuery.trim().toLowerCase();
    final filterStatus = _statusFilter.trim().toLowerCase();

    return _items.where((entry) {
      final invoice = entry.invoice;

      final matchesStatus =
          filterStatus == 'all' ||
              invoice.status.toLowerCase() == filterStatus;

      if (!matchesStatus) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final invNum = invoice.invoiceNumber?.toLowerCase() ?? '';
      final partner = invoice.partnerName?.toLowerCase() ?? '';
      final tax = invoice.taxCode?.toLowerCase() ?? '';
      final cat = entry.transaction.category.toLowerCase();
      final note = entry.transaction.note.toLowerCase();

      return invNum.contains(query) ||
          partner.contains(query) ||
          tax.contains(query) ||
          cat.contains(query) ||
          note.contains(query);
    }).toList(growable: false);
  }

  int get totalCount => _items.length;

  int get confirmedCount {
    return _items.where((entry) {
      return entry.invoice.status.toLowerCase() ==
          'confirmed';
    }).length;
  }

  int get draftCount {
    return _items.where((entry) {
      return entry.invoice.status.toLowerCase() ==
          'draft';
    }).length;
  }

  int get totalAmount {
    return _items.fold<int>(
      0,
          (sum, entry) =>
      sum + entry.invoice.totalAmount,
    );
  }

  Future<void> loadInvoices(
    String userId, {
    String? roleId,
    String? taxCode,
  }) async {
    if (userId.trim().isEmpty) {
      _items = const [];
      _status = InvoiceLoadStatus.error;
      _errorMessage =
      'Không xác định được tài khoản người dùng.';
      notifyListeners();
      return;
    }

    _status = InvoiceLoadStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      debugPrint(
        '[InvoiceProvider] Tải trực tiếp invoice '
        'cho userId=$userId, roleId=$roleId, taxCode=$taxCode',
      );

      final invoicesFuture = _invoiceRepository.getInvoicesByUser(
        userId,
        roleId: roleId,
        taxCode: taxCode,
      );

      final transactionsFuture = _transactionRepository.getTransactions(
        userId,
        roleId: roleId,
      );

      final invoices = await invoicesFuture;
      final transactions = await transactionsFuture;

      debugPrint(
        '[InvoiceProvider] Nhận ${invoices.length} invoice '
            'và ${transactions.length} transaction',
      );

      final transactionMap = <String, TransactionModel>{
        for (final transaction in transactions)
          transaction.transactionId: transaction,
      };

      final loaded = <InvoiceListEntry>[];

      for (final invoice in invoices) {
        final transaction = transactionMap[invoice.transactionId] ??
            TransactionModel(
              transactionId: invoice.transactionId.isNotEmpty
                  ? invoice.transactionId
                  : 'tx_${invoice.invoiceId}',
              userId: invoice.createdBy ?? '',
              categoryId: 'cat_hoadon',
              invoiceId: invoice.invoiceId,
              scanId: invoice.scanId,
              amount: invoice.totalAmount,
              type: TransactionType.expense,
              transactionDate: invoice.invoiceDate ?? DateTime.now(),
              note: 'Hóa đơn ${invoice.invoiceNumber}',
              status: invoice.status,
              createdAt: invoice.invoiceDate ?? DateTime.now(),
            );

        loaded.add(
          InvoiceListEntry(
            invoice: invoice,
            transaction: transaction,
          ),
        );
      }

      loaded.sort((a, b) {
        final aDate =
            a.invoice.invoiceDate ??
                a.transaction.transactionDate;

        final bDate =
            b.invoice.invoiceDate ??
                b.transaction.transactionDate;

        return bDate.compareTo(aDate);
      });

      _items = loaded;
      _status = InvoiceLoadStatus.success;

      debugPrint(
        '[InvoiceProvider] Hiển thị '
            '${_items.length}/${invoices.length} invoice',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[InvoiceProvider] loadInvoices lỗi: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      _items = const [];
      _status = InvoiceLoadStatus.error;
      _errorMessage =
      'Không thể tải danh sách hóa đơn: $error';
    }

    notifyListeners();
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;

    _searchQuery = value;
    notifyListeners();
  }

  void setStatusFilter(String value) {
    if (_statusFilter == value) return;

    _statusFilter = value;
    notifyListeners();
  }

  void addOrUpdateInvoiceEntry(
    InvoiceModel invoice,
    TransactionModel transaction,
  ) {
    final list = List<InvoiceListEntry>.from(_items);
    final index = list.indexWhere((e) => e.invoice.invoiceId == invoice.invoiceId);
    final newEntry = InvoiceListEntry(
      invoice: invoice,
      transaction: transaction,
    );

    if (index != -1) {
      list[index] = newEntry;
    } else {
      list.insert(0, newEntry);
    }

    list.sort((a, b) {
      final aDate = a.invoice.invoiceDate ?? a.transaction.transactionDate;
      final bDate = b.invoice.invoiceDate ?? b.transaction.transactionDate;
      return bDate.compareTo(aDate);
    });

    _items = list;
    _status = InvoiceLoadStatus.success;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = 'all';
    notifyListeners();
  }

  void clear() {
    _items = const [];
    _status = InvoiceLoadStatus.initial;
    _errorMessage = '';
    _searchQuery = '';
    _statusFilter = 'all';
    notifyListeners();
  }
}