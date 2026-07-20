import 'package:flutter/foundation.dart';

import '../../domain/models/invoice_model.dart';
import '../../domain/models/transaction_model.dart';
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

enum InvoiceLoadStatus { initial, loading, success, error }

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
  bool get isLoading => _status == InvoiceLoadStatus.loading;
  bool get isError => _status == InvoiceLoadStatus.error;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  List<InvoiceListEntry> get items => List.unmodifiable(_items);

  List<InvoiceListEntry> get filteredItems {
    final query = _searchQuery.trim().toLowerCase();

    return _items.where((entry) {
      final invoice = entry.invoice;
      final matchesStatus = _statusFilter == 'all' ||
          invoice.status.toLowerCase() == _statusFilter;

      if (!matchesStatus) return false;
      if (query.isEmpty) return true;

      final searchable = <String?>[
        invoice.invoiceNumber,
        invoice.partnerName,
        invoice.taxCode,
        entry.transaction.category,
        entry.transaction.note,
      ].whereType<String>().join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList(growable: false);
  }

  int get totalCount => _items.length;

  int get confirmedCount => _items
      .where((entry) => entry.invoice.status.toLowerCase() == 'confirmed')
      .length;

  int get draftCount => _items
      .where((entry) => entry.invoice.status.toLowerCase() == 'draft')
      .length;

  int get totalAmount => _items.fold<int>(
    0,
        (sum, entry) => sum + entry.invoice.totalAmount,
  );

  Future<void> loadInvoices(String userId) async {
    _status = InvoiceLoadStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final transactions = await _transactionRepository.getTransactions(userId);
      final invoiceTransactions = transactions
          .where((transaction) => transaction.invoiceId != null)
          .toList(growable: false);

      final loaded = await Future.wait(
        invoiceTransactions.map((transaction) async {
          final invoice = await _invoiceRepository
              .getInvoiceForTransaction(transaction.transactionId);
          if (invoice == null) return null;

          return InvoiceListEntry(
            invoice: invoice,
            transaction: transaction,
          );
        }),
      );

      _items = loaded.whereType<InvoiceListEntry>().toList()
        ..sort((a, b) {
          final aDate = a.invoice.invoiceDate ?? a.transaction.transactionDate;
          final bDate = b.invoice.invoiceDate ?? b.transaction.transactionDate;
          return bDate.compareTo(aDate);
        });

      _status = InvoiceLoadStatus.success;
    } catch (error) {
      _status = InvoiceLoadStatus.error;
      _errorMessage = 'Không thể tải danh sách hóa đơn: $error';
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

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = 'all';
    notifyListeners();
  }
}
