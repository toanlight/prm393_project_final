import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class TransactionFormScreen extends StatefulWidget {
  final TransactionModel? transactionToEdit;

  const TransactionFormScreen({super.key, this.transactionToEdit});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form values
  String _amount = '';
  String _type = 'chi';
  String _category = 'Ăn uống';
  DateTime _date = DateTime.now();

  bool _isSaving = false;
  bool get _isEditing => widget.transactionToEdit != null;

  // ==========================================
  // [DEV-3 MOCK DATA] - CẦN THAY THẾ KHI TÍCH HỢP FIREBASE
  // Chức năng: Danh sách danh mục cố định
  // ==========================================
  final List<String> _categories = [
    'Ăn uống',
    'Di chuyển',
    'Lương',
    'Mua sắm',
    'Kinh doanh',
    'Hóa đơn',
    'Khác'
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final tx = widget.transactionToEdit!;
      _amount = tx.amountVnd.toString();
      _type = tx.type;
      _category = _categories.contains(tx.category) ? tx.category : _categories.first;
      _date = tx.date;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSaving = true;
      });

      final int amountVnd = int.parse(_amount);

      // ==========================================
      // [DEV-3 MOCK DATA] - CẦN THAY THẾ KHI TÍCH HỢP FIREBASE
      // Chức năng: Tạo ID giả lập và Gán ID người dùng giả lập
      // ==========================================
      final transaction = TransactionModel(
        id: _isEditing ? widget.transactionToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        amountVnd: amountVnd,
        type: _type,
        category: _category,
        date: _date,
        receiptImageUrl: _isEditing ? widget.transactionToEdit!.receiptImageUrl : null,
        createdBy: _isEditing ? widget.transactionToEdit!.createdBy : 'user_mock_123',
      );

      try {
        final provider = context.read<TransactionProvider>();
        if (_isEditing) {
          await provider.updateTransaction(transaction);
        } else {
          await provider.addTransaction(transaction);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'Cập nhật giao dịch thành công!' : 'Thêm giao dịch thành công!')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa giao dịch' : 'Thêm giao dịch mới'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Số tiền
              TextFormField(
                initialValue: _amount,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (VNĐ)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  final amount = int.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Số tiền phải là số nguyên dương';
                  }
                  return null;
                },
                onSaved: (value) {
                  _amount = value!;
                },
              ),
              const SizedBox(height: 16),

              // Loại giao dịch
              DropdownButtonFormField<String>(
                value: _type,
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
                  setState(() {
                    _type = value!;
                  });
                },
                onSaved: (value) {
                  _type = value!;
                },
              ),
              const SizedBox(height: 16),

              // Danh mục
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value!;
                  });
                },
                onSaved: (value) {
                  _category = value!;
                },
              ),
              const SizedBox(height: 16),

              // Ngày giao dịch
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày giao dịch',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_date),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Nút Lưu
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEditing ? 'Cập nhật' : 'Tạo mới',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
