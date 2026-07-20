import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/services/mock_ocr_service.dart';
import '../../domain/services/mock_receipt_image_store.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';

class TransactionFormScreen extends StatefulWidget {
  final TransactionModel? transactionToEdit;
  final OcrInvoiceData? initialOcrData;

  const TransactionFormScreen({
    super.key,
    this.transactionToEdit,
    this.initialOcrData,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  String _type = 'chi';
  String? _selectedCategoryId;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  bool get _isEditing => widget.transactionToEdit != null;
  bool get _isFromOcr => !_isEditing && widget.initialOcrData != null;

  @override
  void initState() {
    super.initState();

    String initialAmount = '';
    String initialNote = '';

    if (_isEditing) {
      final tx = widget.transactionToEdit!;
      initialAmount = tx.amountVnd.toString();
      _type = tx.type == TransactionType.income ? 'thu' : 'chi';
      _selectedCategoryId = tx.categoryId;
      _date = tx.date;
      initialNote = tx.note;
    } else if (_isFromOcr) {
      final ocr = widget.initialOcrData!;
      initialAmount = ocr.totalAmount.toString();
      _type = 'chi';
      _date = ocr.invoiceDate;
      initialNote = '${ocr.invoiceNumber} - ${ocr.partnerName}';
    }

    _amountController = TextEditingController(text: initialAmount);
    _noteController = TextEditingController(text: initialNote);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _date) {
      setState(() => _date = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isSaving = true);

    final provider = context.read<TransactionProvider>();
    final invoiceRepository = context.read<InvoiceRepository>();
    final authProvider = context.read<AuthProvider>();
    final now = DateTime.now();

    final transactionId = _isEditing
        ? widget.transactionToEdit!.transactionId
        : 'tx_${now.microsecondsSinceEpoch}';

    final invoiceId =
        _isFromOcr ? 'invoice_${now.microsecondsSinceEpoch}' : null;

    final userId = _isEditing
        ? widget.transactionToEdit!.userId
        : (authProvider.user?.uid ?? 'anonymous');

    final transaction = TransactionModel(
      transactionId: transactionId,
      userId: userId,
      categoryId: _selectedCategoryId ?? 'cat_khac',
      invoiceId: invoiceId,
      scanId: _isFromOcr ? widget.initialOcrData!.scanId : null,
      amount: int.parse(_amountController.text),
      type: _type == 'thu'
          ? TransactionType.income
          : TransactionType.expense,
      transactionDate: _date,
      note: _noteController.text.trim(),
      receiptImage: _isFromOcr
          ? 'mock://${widget.initialOcrData!.scanId}'
          : (_isEditing ? widget.transactionToEdit!.receiptImage : null),
      status: _isEditing ? widget.transactionToEdit!.status : 'confirmed',
      createdAt: _isEditing ? widget.transactionToEdit!.createdAt : now,
    );

    bool transactionCreated = false;

    try {
      if (_isEditing) {
        await provider.updateTransaction(transaction);
      } else {
        await provider.addTransaction(transaction);
        transactionCreated = true;
      }

      if (_isFromOcr && invoiceId != null) {
        final invoice = widget.initialOcrData!.toInvoiceModel(
          invoiceId: invoiceId,
          transactionId: transactionId,
          createdBy: userId,
        );

        await invoiceRepository.createInvoice(invoice);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Cập nhật giao dịch thành công!'
                : _isFromOcr
                    ? 'Đã tạo giao dịch và hóa đơn từ OCR!'
                    : 'Thêm giao dịch thành công!',
          ),
        ),
      );

      context.pop();
    } catch (error) {
      if (transactionCreated && _isFromOcr) {
        try {
          await provider.deleteTransaction(transactionId, userId);
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu dữ liệu: $error')),
      );
      setState(() => _isSaving = false);
    }
  }

  void _cancelOcr() {
    final scanId = widget.initialOcrData?.scanId;
    if (scanId != null) {
      MockReceiptImageStore.remove(scanId);
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _isFromOcr) {
          final scanId = widget.initialOcrData?.scanId;
          if (scanId != null) {}
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _isFromOcr
              ? IconButton(
                  onPressed: _cancelOcr,
                  icon: const Icon(Icons.arrow_back),
                )
              : null,
          title: Text(
            _isEditing
                ? 'Chỉnh sửa giao dịch'
                : _isFromOcr
                    ? 'Kiểm tra dữ liệu OCR'
                    : 'Thêm giao dịch mới',
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                if (_isFromOcr) ...[
                  _OcrSummaryCard(data: widget.initialOcrData!),
                  const SizedBox(height: 20),
                ],
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền (VNĐ)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    final amount = int.tryParse(value ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Số tiền phải là số nguyên dương';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Loại',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.swap_horiz),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'thu', child: Text('Thu')),
                    DropdownMenuItem(value: 'chi', child: Text('Chi')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _type = value);
                  },
                ),
                const SizedBox(height: 16),
                Consumer<CategoryProvider>(
                  builder: (context, catProvider, _) {
                    final cats = _type == 'thu'
                        ? catProvider.incomeCategories
                        : catProvider.expenseCategories;

                    if (catProvider.isLoading) {
                      return const LinearProgressIndicator();
                    }

                    if (cats.isNotEmpty &&
                        !cats.any((c) => c.categoryId == _selectedCategoryId)) {
                      _selectedCategoryId = cats.first.categoryId;
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: cats
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat.categoryId,
                              child: Text(cat.categoryName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategoryId = value);
                        }
                      },
                      validator: (v) =>
                          v == null ? 'Vui lòng chọn danh mục' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày giao dịch',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_date)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveTransaction,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(_isEditing ? 'Cập nhật' : 'Tạo mới'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OcrSummaryCard extends StatelessWidget {
  final OcrInvoiceData data;

  const _OcrSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.decimalPattern('vi_VN');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✨ Dữ liệu OCR mô phỏng',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            Text('Số hóa đơn: ${data.invoiceNumber}'),
            Text('Đối tác: ${data.partnerName}'),
            Text('Mã số thuế: ${data.taxCode}'),
            Text('Tiền hàng: ${money.format(data.subTotal)} VNĐ'),
            Text('VAT: ${data.vatRate.toStringAsFixed(0)}%'),
            Text('Tổng cộng: ${money.format(data.totalAmount)} VNĐ'),
          ],
        ),
      ),
    );
  }
}
