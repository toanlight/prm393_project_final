import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/models/invoice_model.dart';
import '../../domain/models/ocr_scan_model.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/repositories/ocr_scan_repository.dart';
import '../../domain/services/finance_calculation_service.dart';
import '../../domain/services/mock_ocr_service.dart';
import '../../domain/services/mock_receipt_image_store.dart';
import '../../domain/services/rbac_permission_service.dart';
import '../../data/services/firebase_receipt_storage_service.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/transaction_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart'
as firebase_auth;


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

  // Cấu hình hóa đơn nhập tay (Bắt buộc cho Thu, Tùy chọn cho Chi)
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
      _invoiceNumberController.text = ocr.invoiceNumber;
      _partnerNameController.text = ocr.partnerName;
      _partnerAddressController.text = ocr.partnerAddress;
      _taxCodeController.text = ocr.taxCode;
      _subTotalController.text = ocr.subTotal.toString();
      _vatRate = ocr.vatRate;
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
    final total = FinanceCalculationService.calculateTotalInvoiceAmount(subTotal, _vatRate.round());
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
          .getInvoiceForTransaction(
        tx.transactionId,
        invoiceId: tx.invoiceId,
      );
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
    if (_isSaving) return;

    // 1. Validate ngay trên thiết bị.
    // Không bật loading, không upload ảnh, không gọi Firebase nếu form chưa hợp lệ.
    final isFormValid =
        _formKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng kiểm tra và nhập đầy đủ các trường bắt buộc.',
          ),
          backgroundColor: AppDesignTokens.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Parse số tiền một lần duy nhất.
    final amountText = _amountController.text.trim();
    final amount = int.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng nhập số tiền lớn hơn 0.',
          ),
          backgroundColor: AppDesignTokens.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 3. Kiểm tra riêng giao dịch Thu.
    int? validatedSubTotal;

    if (_type == 'thu') {
      validatedSubTotal = int.tryParse(
        _subTotalController.text.trim(),
      );

      if (validatedSubTotal == null ||
          validatedSubTotal <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vui lòng nhập tiền hàng lớn hơn 0.',
            ),
            backgroundColor: AppDesignTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    // 4. Chỉ save form và bật loading sau khi dữ liệu hợp lệ.
    _formKey.currentState?.save();

    setState(() => _isSaving = true);

    final provider =
    context.read<TransactionProvider>();
    final invoiceRepository =
    context.read<InvoiceRepository>();
    final authProvider =
    context.read<AuthProvider>();
    final now = DateTime.now();

    try {
      // 5. Kiểm tra Firebase Auth trước khi upload hoặc ghi dữ liệu.
      final firebaseUser =
          firebase_auth.FirebaseAuth.instance.currentUser;

      debugPrint(
        '[ReceiptUpload] AuthProvider UID='
            '${authProvider.user?.uid}',
      );

      debugPrint(
        '[ReceiptUpload] FirebaseAuth UID='
            '${firebaseUser?.uid}',
      );

      debugPrint(
        '[ReceiptUpload] FirebaseAuth email='
            '${firebaseUser?.email}',
      );

      if (firebaseUser == null) {
        throw StateError(
          'Phiên đăng nhập Firebase chưa sẵn sàng. '
              'Vui lòng đăng nhập lại.',
        );
      }

      final userId = firebaseUser.uid;

      // 6. Tạo hoặc sử dụng lại transactionId.
      final transactionId = _isEditing
          ? widget.transactionToEdit!.transactionId
          : 'tx_${now.microsecondsSinceEpoch}';

      // 7. Xác định giao dịch có hóa đơn hay không.
      final hasInvoiceInfo =
          _isFromOcr ||
              _type == 'thu' ||
              _pickedImageBytes != null ||
              _invoiceNumberController.text
                  .trim()
                  .isNotEmpty ||
              _partnerNameController.text
                  .trim()
                  .isNotEmpty;

      // 8. Tạo hoặc sử dụng lại invoiceId.
      final String? invoiceId = hasInvoiceInfo
          ? (
          _isEditing &&
              widget.transactionToEdit!.invoiceId !=
                  null
              ? widget.transactionToEdit!.invoiceId
              : 'invoice_${now.microsecondsSinceEpoch}'
      )
          : null;

      // 9. Xác định scanId.
      String? scanId = _isFromOcr
          ? widget.initialOcrData!.scanId
          : (
          _isEditing
              ? widget.transactionToEdit!.scanId
              : null
      );

      // 10. Lấy bytes ảnh.
      Uint8List? receiptBytes = _pickedImageBytes;

      if (_isFromOcr && receiptBytes == null) {
        receiptBytes = MockReceiptImageStore.get(
          widget.initialOcrData!.scanId,
        );
      }

      if (receiptBytes != null) {
        scanId ??=
        'scan_${_type}_${now.microsecondsSinceEpoch}';
      }

      // 11. Giữ URL ảnh cũ khi edit.
      String? receiptDownloadUrl = _isEditing
          ? widget.transactionToEdit!.receiptImage
          : null;

      // 12. Chỉ upload sau khi toàn bộ dữ liệu đầu vào hợp lệ.
      if (receiptBytes != null && scanId != null) {
        receiptDownloadUrl =
        await FirebaseReceiptStorageService
            .uploadReceipt(
          userId: userId,
          transactionId: transactionId,
          scanId: scanId,
          bytes: receiptBytes,
          fileName: _pickedImage?.name,
        );
      }

      // 13. Tạo TransactionModel.
      final transaction = TransactionModel(
        transactionId: transactionId,
        userId: userId,
        categoryId:
        _selectedCategoryId ?? 'cat_khac',
        invoiceId: invoiceId,
        scanId: scanId,
        amount: amount,
        type: _type == 'thu'
            ? TransactionType.income
            : TransactionType.expense,
        transactionDate: _date,
        note: _noteController.text.trim(),
        receiptImage: receiptDownloadUrl,
        status: _isEditing
            ? widget.transactionToEdit!.status
            : 'pending',
        createdAt: _isEditing
            ? widget.transactionToEdit!.createdAt
            : now,
      );

      bool transactionCreated = false;
      bool invoiceChanged = false;

      // 14. Lưu transaction.
      if (_isEditing) {
        await provider.updateTransaction(
          transaction,
        );
      } else {
        await provider.addTransaction(
          transaction,
        );
        transactionCreated = true;
      }

      // 15. Tạo hóa đơn từ OCR.
      if (_isFromOcr && invoiceId != null) {
        final invoice =
        widget.initialOcrData!.toInvoiceModel(
          invoiceId: invoiceId,
          transactionId: transactionId,
          createdBy: userId,
        );

        await invoiceRepository.createInvoice(
          invoice,
        );

        invoiceChanged = true;
      }

      // 16. Tạo hóa đơn nhập tay.
      else if (hasInvoiceInfo &&
          invoiceId != null) {
        final totalAmount = amount;

        final subTotal = validatedSubTotal ??
            int.tryParse(
              _subTotalController.text.trim(),
            ) ??
            (
                _type == 'thu'
                    ? totalAmount
                    : (
                    totalAmount /
                        (1 + _vatRate / 100)
                ).round()
            );

        final vatAmount =
            totalAmount - subTotal;

        final invoiceNumberText =
        _invoiceNumberController.text.trim();

        final partnerNameText =
        _partnerNameController.text.trim();

        final invoiceNumber =
        invoiceNumberText.isNotEmpty
            ? invoiceNumberText
            : 'HĐ ${_type == 'thu' ? 'Thu' : 'Chi'} '
            '#${now.millisecondsSinceEpoch.toString().substring(5)}';

        final partnerName =
        partnerNameText.isNotEmpty
            ? partnerNameText
            : (
            _type == 'thu'
                ? 'Khách hàng'
                : 'Nhà cung cấp / Đối tác'
        );

        final manualInvoice = InvoiceModel(
          invoiceId: invoiceId,
          transactionId: transactionId,
          invoiceNumber: invoiceNumber,
          partnerName: partnerName,
          partnerAddress:
          _partnerAddressController.text.trim(),
          taxCode:
          _taxCodeController.text.trim(),
          invoiceDate: _date,
          subTotal: subTotal,
          vatRate: _vatRate,
          vatAmount:
          vatAmount > 0 ? vatAmount : 0,
          totalAmount: totalAmount,
          pdfPath:
          'invoices/pdf/$invoiceId.pdf',
          createdBy: userId,
          scanId: scanId,
          status: transaction.status,
        );

        await invoiceRepository.createInvoice(
          manualInvoice,
        );

        invoiceChanged = true;
      }

      // 17. Lưu OCR scan nếu có ảnh thật và invoice.
      if (scanId != null &&
          receiptDownloadUrl != null &&
          invoiceId != null) {
        final ocrScan = OCRScanModel(
          scanId: scanId,
          userId: userId,
          imagePath: receiptDownloadUrl,
          extractedAmount: amount,
          extractedTaxCode:
          _taxCodeController.text.trim(),
          extractedDate: _date,
          rawJson: '{}',
          status: 'completed',
          transactionId: transactionId,
          invoiceId: invoiceId,
          createdAt: now,
        );

        await context
            .read<OCRScanRepository>()
            .createOCRScan(ocrScan);
      }

      // 18. Đồng bộ lại danh sách hóa đơn.
      if (invoiceChanged && mounted) {
        await context
            .read<InvoiceProvider>()
            .loadInvoices(userId);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            transactionCreated
                ? 'Đã tạo giao dịch mới thành công'
                : 'Đã cập nhật giao dịch',
          ),
          backgroundColor:
          AppDesignTokens.success,
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      if (_isFromOcr) {
        context.go('/invoices');
      } else {
        context.pop();
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[TransactionForm] Không thể lưu giao dịch: '
            '$error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể lưu giao dịch: $error',
          ),
          backgroundColor:
          AppDesignTokens.error,
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _cancelOcr() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;

    final canAccess = _isEditing
        ? RbacPermissionService.canEditTransaction(user)
        : RbacPermissionService.canCreateTransaction(user);

    if (!canAccess) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDesignTokens.spaceLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.block_rounded,
                  color: AppDesignTokens.error,
                  size: 64,
                ),
                const SizedBox(height: AppDesignTokens.spaceMd),
                Text(
                  'Quyền truy cập bị từ chối',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppDesignTokens.spaceSm),
                Text(
                  'Tài khoản của bạn không có quyền ${_isEditing ? "chỉnh sửa" : "tạo mới"} giao dịch.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark
                        ? AppDesignTokens.darkTextSecondary
                        : AppDesignTokens.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spaceLg),
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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

                // Cấu hình Hóa đơn & Chứng từ đính kèm (Bắt buộc cho Thu, Tùy chọn cho Chi)
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: _type == 'thu' ? AppDesignTokens.primary : AppDesignTokens.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _type == 'thu'
                          ? 'Thông tin hóa đơn (Bắt buộc)'
                          : 'Thông tin hóa đơn / Chứng từ (Tùy chọn)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _type == 'thu' ? AppDesignTokens.primary : AppDesignTokens.error,
                      ),
                    ),
                  ],
                ),
                Divider(
                  color: _type == 'thu' ? AppDesignTokens.primary : AppDesignTokens.error,
                  thickness: 1,
                ),
                const SizedBox(height: 16),

                // Khối tải ảnh chứng từ / Hóa đơn
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
                      Text(
                        _type == 'thu' ? 'Ảnh hóa đơn chứng từ' : 'Ảnh hóa đơn / Biên lai chi (Tùy chọn)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                                height: 140,
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
                        label: Text(_pickedImageBytes != null ? 'Thay đổi ảnh chứng từ' : 'Chọn ảnh chứng từ từ thư viện'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Các trường chi tiết hóa đơn
                TextFormField(
                  controller: _invoiceNumberController,
                  decoration: InputDecoration(
                    labelText: _type == 'thu' ? 'Số hóa đơn *' : 'Số hóa đơn (Nếu có)',
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
                    labelText: _type == 'thu' ? 'Tên đối tác *' : 'Tên nhà cung cấp / Đối tác (Nếu có)',
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

                if (_type == 'thu') ...[
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
