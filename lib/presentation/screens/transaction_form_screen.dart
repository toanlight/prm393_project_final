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
import '../providers/invoice_provider.dart';
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
    String? scanId = _isFromOcr
        ? widget.initialOcrData!.scanId
        : (_isEditing ? widget.transactionToEdit!.scanId : null);

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
        : (authProvider.user?.uid ?? 'mock-user-123');

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
      status: _isEditing ? widget.transactionToEdit!.status : 'pending',
      createdAt: _isEditing ? widget.transactionToEdit!.createdAt : now,
    );

    bool transactionCreated = false;
    bool invoiceChanged = false;

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
        invoiceChanged = true;
      } else if (_type == 'thu' && invoiceId != null) {
        final subTotal = int.tryParse(_subTotalController.text) ?? 0;
        final vatAmount = (subTotal * _vatRate / 100).round();
        final totalAmount = subTotal + vatAmount;

        final manualInvoice = InvoiceModel(
          invoiceId: invoiceId,
          transactionId: transactionId,
          invoiceNumber: _invoiceNumberController.text.trim(),
          partnerName: _partnerNameController.text.trim(),
          partnerAddress: _partnerAddressController.text.trim(),
          taxCode: _taxCodeController.text.trim(),
          invoiceDate: _date,
          subTotal: subTotal,
          vatRate: _vatRate,
          vatAmount: vatAmount,
          totalAmount: totalAmount,
          pdfPath: 'invoices/pdf/$invoiceId.pdf',
          createdBy: userId,
          scanId: scanId,
          status: 'confirmed',
        );

        await invoiceRepository.createInvoice(manualInvoice);
        invoiceChanged = true;
      }

      // StatefulShellRoute giữ nguyên trạng thái của tab Hóa đơn.
      // Vì vậy, sau khi tạo/cập nhật hóa đơn từ tab Giao dịch,
      // cần chủ động tải lại InvoiceProvider để hóa đơn xuất hiện ngay
      // khi người dùng chuyển sang trang Hóa đơn.
      if (invoiceChanged && mounted) {
        await context.read<InvoiceProvider>().loadInvoices(userId);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            transactionCreated
                ? 'Đã tạo giao dịch mới thành công'
                : 'Đã cập nhật giao dịch',
          ),
          backgroundColor: AppDesignTokens.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lưu giao dịch: $e'),
          backgroundColor: AppDesignTokens.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _cancelOcr() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _isFromOcr ? _cancelOcr : () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.spaceLg),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // 1. Tiêu đề lớn
                Text(
                  _isEditing
                      ? 'Chỉnh sửa giao dịch'
                      : _isFromOcr
                      ? 'Kiểm tra dữ liệu OCR'
                      : 'Thêm giao dịch mới',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 20),

                if (_isFromOcr) ...[
                  _OcrSummaryCard(data: widget.initialOcrData!),
                  const SizedBox(height: 20),
                ],

                // 2. Loại giao dịch * (Segmented Toggle Control)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loại giao dịch *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppDesignTokens.darkSurfaceCard : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                        border: Border.all(
                          color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _type = 'thu';
                                  _updateTotalAmount();
                                });
                              },
                              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _type == 'thu' ? AppDesignTokens.success : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Thu',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _type == 'thu'
                                        ? Colors.white
                                        : (isDark ? AppDesignTokens.darkTextPrimary : AppDesignTokens.lightTextPrimary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _type = 'chi';
                                  _updateTotalAmount();
                                });
                              },
                              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _type == 'chi' ? AppDesignTokens.error : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Chi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _type == 'chi'
                                        ? Colors.white
                                        : (isDark ? AppDesignTokens.darkTextPrimary : AppDesignTokens.lightTextPrimary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Số tiền (VND) *
                TextFormField(
                  controller: _amountController,
                  readOnly: _type == 'thu', // Khóa không cho sửa tiền trực tiếp khi là Thu
                  decoration: InputDecoration(
                    labelText: _type == 'thu' ? 'Số tiền (Tổng tiền hàng + VAT) *' : 'Số tiền (VND) *',
                    hintText: '0',
                    suffixIcon: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'đ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                    ),
                    prefixIcon: const Icon(Icons.payments_outlined),
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
                const SizedBox(height: 20),

                // Danh mục
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
                      decoration: InputDecoration(
                        labelText: 'Danh mục *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                        ),
                        prefixIcon: const Icon(Icons.category_outlined),
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
                      validator: (v) => v == null ? 'Vui lòng chọn danh mục' : null,
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Ngày giao dịch
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Ngày giao dịch *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_date)),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Ghi chú (Multiline + Bộ đếm 0/200)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ghi chú',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                          ),
                        ),
                        Text(
                          '${_noteController.text.length}/200',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _noteController,
                      maxLength: 200,
                      maxLines: 3,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Ghi chú thêm về giao dịch...',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                        ),
                      ),
                    ),
                  ],
                ),

                // Cấu hình hóa đơn thủ công khi Loại = Thu
                if (_type == 'thu') ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: AppDesignTokens.primary),
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
                  const Divider(color: AppDesignTokens.primary, thickness: 1),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _invoiceNumberController,
                    decoration: InputDecoration(
                      labelText: 'Số hóa đơn *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                      ),
                      prefixIcon: const Icon(Icons.numbers),
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
                    decoration: InputDecoration(
                      labelText: 'Tên đối tác *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                      ),
                      prefixIcon: const Icon(Icons.business),
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
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ đối tác',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                      ),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _taxCodeController,
                    decoration: InputDecoration(
                      labelText: 'Mã số thuế',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                      ),
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _subTotalController,
                          decoration: InputDecoration(
                            labelText: 'Tiền hàng *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                            ),
                            prefixIcon: const Icon(Icons.monetization_on_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (_type == 'thu') {
                              final amount = int.tryParse(value ?? '');
                              if (amount == null || amount <= 0) {
                                return 'Nhập tiền hàng';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<double>(
                          value: _vatRate,
                          decoration: InputDecoration(
                            labelText: 'VAT %',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 0.0, child: Text('0%')),
                            DropdownMenuItem(value: 8.0, child: Text('8%')),
                            DropdownMenuItem(value: 10.0, child: Text('10%')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _vatRate = val;
                                _updateTotalAmount();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
                      ),
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                    ),
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
                ],

                const SizedBox(height: 32),

                // 8. Thanh điều hướng dưới cùng (2 Button nằm ngang: Hủy 45%, Lưu 55%)
                Row(
                  children: [
                    Expanded(
                      flex: 45,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                            ),
                          ),
                          child: Text(
                            'Hủy',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppDesignTokens.darkTextPrimary : AppDesignTokens.lightTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 55,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveTransaction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppDesignTokens.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : const Text(
                            'Lưu giao dịch',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: isDark
            ? AppDesignTokens.primary.withOpacity(0.15)
            : AppDesignTokens.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        border: Border.all(color: AppDesignTokens.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppDesignTokens.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Dữ liệu trích xuất từ hóa đơn (OCR)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppDesignTokens.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.spaceSm),
          Text('• Số HĐ: ${data.invoiceNumber}'),
          Text('• Đối tác: ${data.partnerName}'),
          Text('• MST: ${data.taxCode}'),
          Text('• Tiền hàng: ${data.subTotal} đ | VAT (${data.vatRate}%): ${data.vatAmount} đ'),
          Text(
            '• Tổng cộng: ${data.totalAmount} đ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
