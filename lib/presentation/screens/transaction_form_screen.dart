import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/models/invoice_model.dart';
import '../../domain/models/ocr_invoice_data.dart';
import '../../domain/models/ocr_scan_model.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/repositories/ocr_scan_repository.dart';
import '../../domain/services/finance_calculation_service.dart';
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

  // Giới hạn nghiệp vụ: tối đa 999.999.999.999 VND.
  // 12 chữ số cũng an toàn khi chạy Flutter Web và đủ cho giao dịch SME.
  static const int _maxMoneyVnd = 999999999999;
  static const int _maxMoneyDigits = 12;

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

  String? _validateMoney(
      String? value, {
        required String fieldName,
      }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }

    if (!RegExp(r'^\d+$').hasMatch(text)) {
      return '$fieldName chỉ được chứa chữ số';
    }

    // Kiểm tra độ dài trước khi parse để chặn chuỗi số cực lớn.
    if (text.length > _maxMoneyDigits) {
      return '$fieldName không được vượt quá 999.999.999.999 đ';
    }

    final amount = int.tryParse(text);
    if (amount == null || amount <= 0) {
      return '$fieldName phải lớn hơn 0';
    }

    if (amount > _maxMoneyVnd) {
      return '$fieldName không được vượt quá 999.999.999.999 đ';
    }

    return null;
  }

  String _generateUniqueId(String prefix) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rand = (100000 + (ts % 900000)).toString();
    return '${prefix}_${ts}_$rand';
  }

  bool _isDuplicateInvoice = false;
  Timer? _debounceTimer;

  void _onInvoiceInputChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _checkDuplicateInvoice();
      }
    });
  }

  Future<void> _checkDuplicateInvoice() async {
    final invoiceNumber = _invoiceNumberController.text.trim();
    final taxCode = _taxCodeController.text.trim();

    if (invoiceNumber.isEmpty || taxCode.isEmpty) {
      if (_isDuplicateInvoice) {
        setState(() => _isDuplicateInvoice = false);
      }
      return;
    }

    try {
      final isDup = await context.read<InvoiceRepository>().checkDuplicateInvoice(
        taxCode,
        invoiceNumber,
        excludeInvoiceId: widget.transactionToEdit?.invoiceId,
      );

      if (mounted && isDup != _isDuplicateInvoice) {
        setState(() => _isDuplicateInvoice = isDup);
      }
    } catch (_) {}
  }

  void _updateTotalAmount() {
    final text = _subTotalController.text.trim();
    if (text.isEmpty) return;

    if (_validateMoney(text, fieldName: 'Tiền hàng') != null) {
      return;
    }

    final subTotal = int.parse(text);
    final total = FinanceCalculationService.calculateTotalInvoiceAmount(
      subTotal,
      _vatRate,
    );

    if (total > 0 && total <= _maxMoneyVnd) {
      _amountController.text = total.toString();
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
        });
        _checkDuplicateInvoice();
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
    _debounceTimer?.cancel();
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
    final isFormValid = _formKey.currentState?.validate() ?? false;

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

    // 2. Parse số tiền.
    final amountText = _amountController.text.trim();
    final amount = int.tryParse(amountText);

    final amountError = _validateMoney(
      amountText,
      fieldName: 'Số tiền',
    );

    if (amountError != null || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(amountError ?? 'Số tiền không hợp lệ.'),
          backgroundColor: AppDesignTokens.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 3. Quy tắc BA: Chi BẮT BUỘC có hóa đơn hợp lệ! Thu có thể có hoặc không.
    int? validatedSubTotal;

    if (_type == 'chi') {
      final subText = _subTotalController.text.trim();
      validatedSubTotal = int.tryParse(subText);

      final subTotalError = _validateMoney(
        subText,
        fieldName: 'Tiền hàng',
      );

      if (subTotalError != null || validatedSubTotal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(subTotalError ?? 'Giao dịch Chi bắt buộc phải có thông tin Tiền hàng hóa đơn hợp lệ.'),
            backgroundColor: AppDesignTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else {
      final subText = _subTotalController.text.trim();
      validatedSubTotal = int.tryParse(subText);

      // Nếu Giao dịch Thu có chọn VAT > 0%, yêu cầu nhập Tiền hàng để tính đúng VAT.
      if (_vatRate > 0 && subText.isNotEmpty) {
        final subTotalError = _validateMoney(subText, fieldName: 'Tiền hàng');
        if (subTotalError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(subTotalError),
              backgroundColor: AppDesignTokens.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
    }

    // 4. Chỉ save form và bật loading sau khi dữ liệu hợp lệ.
    _formKey.currentState?.save();

    setState(() => _isSaving = true);

    final provider = context.read<TransactionProvider>();
    final invoiceRepository = context.read<InvoiceRepository>();
    final authProvider = context.read<AuthProvider>();
    final now = DateTime.now();

    try {
      final userId = authProvider.user?.uid ??
          firebase_auth.FirebaseAuth.instance.currentUser?.uid;

      if (userId == null || userId.isEmpty) {
        throw StateError(
          'Phiên đăng nhập chưa sẵn sàng. Vui lòng đăng nhập lại.',
        );
      }

      // 6. Tạo hoặc sử dụng lại transactionId.
      final transactionId = _isEditing
          ? widget.transactionToEdit!.transactionId
          : _generateUniqueId('tx');

      // 7. Quy tắc BA: Chi bắt buộc tạo Hóa đơn. Thu có Hóa đơn nếu nhập số HĐ/Đối tác/Ảnh.
      final hasInvoiceInfo = _type == 'chi' ||
          _isFromOcr ||
          _pickedImageBytes != null ||
          _invoiceNumberController.text.trim().isNotEmpty ||
          _partnerNameController.text.trim().isNotEmpty;

      // 8. Tạo hoặc sử dụng lại invoiceId.
      final String? invoiceId = hasInvoiceInfo
          ? (
          _isEditing && widget.transactionToEdit!.invoiceId != null
              ? widget.transactionToEdit!.invoiceId
              : _generateUniqueId('invoice')
      )
          : null;

      // 9. Xác định scanId.
      String? scanId = _isFromOcr
          ? widget.initialOcrData!.scanId
          : (_isEditing ? widget.transactionToEdit!.scanId : null);

      Uint8List? receiptBytes = _pickedImageBytes;

      if (receiptBytes != null) {
        scanId ??= _generateUniqueId('scan_${_type}');
      }

      String? receiptDownloadUrl = _isEditing
          ? widget.transactionToEdit!.receiptImage
          : null;

      if (receiptBytes != null && scanId != null) {
        receiptDownloadUrl = await FirebaseReceiptStorageService.uploadReceipt(
          userId: userId,
          transactionId: transactionId,
          scanId: scanId,
          bytes: receiptBytes,
          fileName: _pickedImage?.name,
        );
      }

      final transaction = TransactionModel(
        transactionId: transactionId,
        userId: userId,
        categoryId: _selectedCategoryId ?? 'cat_khac',
        invoiceId: invoiceId,
        scanId: scanId,
        amount: amount,
        type: _type == 'thu' ? TransactionType.income : TransactionType.expense,
        transactionDate: _date,
        note: _noteController.text.trim(),
        receiptImage: receiptDownloadUrl,
        status: _isEditing ? widget.transactionToEdit!.status : 'pending',
        createdAt: _isEditing ? widget.transactionToEdit!.createdAt : now,
      );

      bool transactionCreated = false;

      if (_isEditing) {
        await provider.updateTransaction(transaction);
      } else {
        await provider.addTransaction(transaction);
        transactionCreated = true;
      }

      InvoiceModel? createdInvoice;

      try {
        if (_isFromOcr && invoiceId != null) {
          createdInvoice = widget.initialOcrData!.toInvoiceModel(
            invoiceId: invoiceId,
            transactionId: transactionId,
            createdBy: userId,
          );
          await invoiceRepository.createInvoice(createdInvoice);
        } else if (hasInvoiceInfo && invoiceId != null) {
          final subTotal = validatedSubTotal ?? amount;
          final vatAmount = FinanceCalculationService.calculateVatAmount(
            subTotal,
            _vatRate,
          );
          final totalAmount = FinanceCalculationService.calculateTotalInvoiceAmount(
            subTotal,
            _vatRate,
          );

          final invoiceNumberText = _invoiceNumberController.text.trim();
          final partnerNameText = _partnerNameController.text.trim();

          final invoiceNumber = invoiceNumberText.isNotEmpty
              ? invoiceNumberText
              : 'HĐ ${_type == 'thu' ? 'Thu' : 'Chi'} #${now.millisecondsSinceEpoch.toString().substring(5)}';

          final partnerName = partnerNameText.isNotEmpty
              ? partnerNameText
              : (_type == 'thu' ? 'Khách hàng' : 'Nhà cung cấp / Đối tác');

          createdInvoice = InvoiceModel(
            invoiceId: invoiceId,
            transactionId: transactionId,
            invoiceNumber: invoiceNumber,
            partnerName: partnerName,
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
            status: transaction.status,
          );

          await invoiceRepository.createInvoice(createdInvoice);
        }
      } catch (invoiceError) {
        // Cơ chế Transactional Rollback: Nếu tạo Invoice thất bại khi vừa tạo Transaction mới,
        // lập tức rollback (xóa) Transaction để không để lại Transaction Chi mồ côi.
        if (transactionCreated) {
          debugPrint('⚠️ Transactional Rollback: Xóa transaction $transactionId do tạo invoice thất bại');
          try {
            await provider.deleteTransaction(transactionId, userId);
          } catch (rollbackErr) {
            debugPrint('⚠️ Lỗi Rollback transaction: $rollbackErr');
          }
        }
        rethrow;
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

      // 18. Cập nhật mượt mà vào InvoiceProvider local state (Tránh re-fetch toàn bộ document qua mạng)
      if (createdInvoice != null) {
        context.read<InvoiceProvider>().addOrUpdateInvoiceEntry(createdInvoice, transaction);
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
                              onTap: RbacPermissionService.canCreateExpenseTransaction(user)
                                  ? () {
                                setState(() {
                                  _type = 'chi';
                                  _updateTotalAmount();
                                });
                              }
                                  : null,
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
                                        : (RbacPermissionService.canCreateExpenseTransaction(user)
                                        ? (isDark ? AppDesignTokens.darkTextPrimary : AppDesignTokens.lightTextPrimary)
                                        : Colors.grey),
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
                    LengthLimitingTextInputFormatter(_maxMoneyDigits),
                  ],
                  validator: (value) => _validateMoney(
                    value,
                    fieldName: 'Số tiền',
                  ),
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
                      color: _type == 'chi' ? AppDesignTokens.error : AppDesignTokens.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _type == 'chi'
                          ? 'Thông tin hóa đơn (Bắt buộc cho Chi)'
                          : 'Thông tin hóa đơn / Chứng từ (Tùy chọn cho Thu)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _type == 'chi' ? AppDesignTokens.error : AppDesignTokens.primary,
                      ),
                    ),
                  ],
                ),
                Divider(
                  color: _type == 'chi' ? AppDesignTokens.error : AppDesignTokens.primary,
                  thickness: 1,
                ),
                const SizedBox(height: 16),

                if (_isDuplicateInvoice) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cảnh báo: Hóa đơn có Số HĐ và Mã số thuế này đã tồn tại trên hệ thống.',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

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
                        _type == 'chi' ? 'Ảnh hóa đơn / Biên lai chi *' : 'Ảnh hóa đơn chứng từ (Tùy chọn)',
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
                  onChanged: (_) => _onInvoiceInputChanged(),
                  decoration: InputDecoration(
                    labelText: _type == 'chi' ? 'Số hóa đơn *' : 'Số hóa đơn (Nếu có)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                    ),
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                  validator: (value) {
                    if (_type == 'chi' && (value == null || value.trim().isEmpty)) {
                      return 'Giao dịch Chi bắt buộc phải nhập số hóa đơn';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _partnerNameController,
                  decoration: InputDecoration(
                    labelText: _type == 'chi' ? 'Tên nhà cung cấp / Đối tác *' : 'Tên đối tác (Nếu có)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                    ),
                    prefixIcon: const Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (_type == 'chi' && (value == null || value.trim().isEmpty)) {
                      return 'Giao dịch Chi bắt buộc nhập tên nhà cung cấp';
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
                  onChanged: (_) => _onInvoiceInputChanged(),
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
                          labelText: _type == 'chi' ? 'Tiền hàng *' : 'Tiền hàng (Nếu có)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                          ),
                          prefixIcon: const Icon(Icons.monetization_on_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_maxMoneyDigits),
                        ],
                        validator: (value) {
                          if (_type == 'chi') {
                            return _validateMoney(
                              value,
                              fieldName: 'Tiền hàng',
                            );
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
