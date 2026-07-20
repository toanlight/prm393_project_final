import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/models/invoice_model.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/services/mock_ocr_service.dart';
import '../../domain/services/mock_receipt_image_store.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import 'package:image_picker/image_picker.dart';

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

  // Cấu hình hóa đơn nhập tay khi _type == 'thu'
  final _invoiceNumberController = TextEditingController();
  final _partnerNameController = TextEditingController();
  final _partnerAddressController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _subTotalController = TextEditingController();

  double _vatRate = 10.0;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

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

      // Tải hóa đơn liên kết nếu có
      if (tx.invoiceId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadLinkedInvoice(tx));
      }
    } else if (_isFromOcr) {
      final ocr = widget.initialOcrData!;
      initialAmount = ocr.totalAmount.toString();
      _type = 'chi';
      _date = ocr.invoiceDate;
      initialNote = '${ocr.invoiceNumber} - ${ocr.partnerName}';
    }

    _amountController = TextEditingController(text: initialAmount);
    _noteController = TextEditingController(text: initialNote);

    _subTotalController.addListener(_updateTotalAmount);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  void _updateTotalAmount() {
    if (_type != 'thu') return;
    final subTotal = int.tryParse(_subTotalController.text) ?? 0;
    final vatAmount = (subTotal * _vatRate / 100).round();
    final total = subTotal + vatAmount;
    if (total > 0) {
      _amountController.text = total.toString();
    } else {
      _amountController.text = '';
    }
  }

  Future<void> _loadLinkedInvoice(TransactionModel tx) async {
    try {
      final invoice = await context
          .read<InvoiceRepository>()
          .getInvoiceForTransaction(tx.transactionId);
      if (invoice != null && mounted) {
        setState(() {
          _invoiceNumberController.text = invoice.invoiceNumber ?? '';
          _partnerNameController.text = invoice.partnerName ?? '';
          _partnerAddressController.text = invoice.partnerAddress ?? '';
          _taxCodeController.text = invoice.taxCode ?? '';
          _subTotalController.text = invoice.subTotal.toString();
          _vatRate = invoice.vatRate;

          if (tx.scanId != null) {
            _pickedImageBytes = MockReceiptImageStore.get(tx.scanId!);
          }
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải hóa đơn liên kết: $e");
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedImage = image;
          _pickedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ảnh: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _invoiceNumberController.dispose();
    _partnerNameController.dispose();
    _partnerAddressController.dispose();
    _taxCodeController.dispose();
    _subTotalController.dispose();
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

    // Khởi tạo các mã liên kết hóa đơn
    String? invoiceId = _isFromOcr
        ? 'invoice_${now.microsecondsSinceEpoch}'
        : (_isEditing ? widget.transactionToEdit!.invoiceId : null);
    String? scanId = _isEditing ? widget.transactionToEdit!.scanId : null;

    if (_type == 'thu') {
      invoiceId ??= 'invoice_${now.microsecondsSinceEpoch}';
      if (_pickedImageBytes != null) {
        scanId ??= 'scan_manual_${now.microsecondsSinceEpoch}';
        MockReceiptImageStore.save(scanId: scanId, bytes: _pickedImageBytes!);
      }
    } else if (!_isFromOcr) {
      // Nếu đổi từ thu sang chi, ta xóa liên kết hóa đơn
      invoiceId = null;
      scanId = null;
    }

    final userId = _isEditing
        ? widget.transactionToEdit!.userId
        : (authProvider.user?.uid ?? 'anonymous');

    final transaction = TransactionModel(
      transactionId: transactionId,
      userId: userId,
      categoryId: _selectedCategoryId ?? 'cat_khac',
      invoiceId: invoiceId,
      scanId: scanId,
      amount: int.parse(_amountController.text),
      type: _type == 'thu'
          ? TransactionType.income
          : TransactionType.expense,
      transactionDate: _date,
      note: _noteController.text.trim(),
      receiptImage: _isFromOcr
          ? 'mock://${widget.initialOcrData!.scanId}'
          : (scanId != null
              ? 'mock://$scanId'
              : (_type == 'thu' && _isEditing ? widget.transactionToEdit!.receiptImage : null)),
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
      } else if (_type == 'thu' && invoiceId != null) {
        final subTotal = int.tryParse(_subTotalController.text) ?? 0;
        final vatAmount = (subTotal * _vatRate / 100).round();
        final totalAmount = subTotal + vatAmount;

        final invoice = InvoiceModel(
          invoiceId: invoiceId,
          transactionId: transactionId,
          invoiceNumber: _invoiceNumberController.text,
          partnerName: _partnerNameController.text,
          partnerAddress: _partnerAddressController.text,
          taxCode: _taxCodeController.text,
          invoiceDate: _date,
          subTotal: subTotal,
          vatRate: _vatRate,
          vatAmount: vatAmount,
          totalAmount: totalAmount,
          pdfPath: 'invoices/pdf/$invoiceId.pdf',
          createdBy: userId,
          scanId: scanId,
          status: 'confirmed', // Phê duyệt để xem được PDF
        );

        await invoiceRepository.createInvoice(invoice);
      } else if (_isEditing && widget.transactionToEdit!.type == TransactionType.income && _type == 'chi') {
        // Chuyển từ Thu sang Chi, xóa hóa đơn cũ
        if (widget.transactionToEdit!.invoiceId != null) {
          await invoiceRepository.deleteInvoice(transactionId, widget.transactionToEdit!.invoiceId!);
        }
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

      context.pop(true);
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
                  readOnly: _type == 'thu', // Khóa không cho sửa tiền trực tiếp khi là Thu
                  decoration: InputDecoration(
                    labelText: _type == 'thu' ? 'Số tiền (Tổng tiền hàng + VAT)' : 'Số tiền (VNĐ)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.money),
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
                    if (value != null) {
                      setState(() {
                        _type = value;
                        // Reset hoặc cập nhật tính toán lại tiền khi đổi loại
                        _updateTotalAmount();
                      });
                    }
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
                if (_type == 'thu') ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: AppDesignTokens.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Thông tin hóa đơn (Bắt buộc)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppDesignTokens.primary,
                            ),
                      ),
                    ],
                  ),
                  Divider(color: AppDesignTokens.primary, thickness: 1),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _invoiceNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Số hóa đơn',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    validator: (value) {
                      if (_type == 'thu' && (value == null || value.trim().isEmpty)) {
                        return 'Vui lòng nhập số hóa đơn';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _partnerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên đối tác',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (_type == 'thu' && (value == null || value.trim().isEmpty)) {
                        return 'Vui lòng nhập tên đối tác';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _partnerAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ đối tác',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (_type == 'thu' && (value == null || value.trim().isEmpty)) {
                        return 'Vui lòng nhập địa chỉ đối tác';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _taxCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Mã số thuế đối tác',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (_type == 'thu') {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập mã số thuế';
                        }
                        if (value.length < 10 || value.length > 13) {
                          return 'Mã số thuế phải từ 10 đến 13 chữ số';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _subTotalController,
                          decoration: const InputDecoration(
                            labelText: 'Tiền hàng (chưa thuế)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (_type == 'thu') {
                              final sub = int.tryParse(value ?? '');
                              if (sub == null || sub <= 0) {
                                return 'Nhập số tiền hàng';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<double>(
                          value: _vatRate,
                          decoration: const InputDecoration(
                            labelText: 'VAT',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 0.0, child: Text('0%')),
                            DropdownMenuItem(value: 5.0, child: Text('5%')),
                            DropdownMenuItem(value: 8.0, child: Text('8%')),
                            DropdownMenuItem(value: 10.0, child: Text('10%')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _vatRate = value;
                                _updateTotalAmount();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Đính kèm ảnh hóa đơn
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ảnh hóa đơn (Tùy chọn)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (_pickedImageBytes != null) ...[
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                                  child: Image.memory(
                                    _pickedImageBytes!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  radius: 16,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _pickedImage = null;
                                        _pickedImageBytes = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: Text(_pickedImageBytes != null ? 'Thay đổi ảnh' : 'Chọn ảnh từ thư viện'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
>>>>>>> origin/feature/transactions-ui-form
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
