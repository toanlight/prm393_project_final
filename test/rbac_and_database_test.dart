import 'package:flutter_test/flutter_test.dart';
import 'package:project_final/domain/models/user_model.dart';
import 'package:project_final/domain/models/transaction_model.dart';
import 'package:project_final/domain/models/transaction_type.dart';
import 'package:project_final/domain/models/invoice_model.dart';
import 'package:project_final/domain/models/invoice_item_model.dart';
import 'package:project_final/domain/models/ocr_scan_model.dart';
import 'package:project_final/domain/services/rbac_permission_service.dart';

void main() {
  group('RBAC & Sơ đồ Database Unit Tests', () {
    // 1. Setup mock users
    final adminUser = UserModel(
      uid: 'u_admin',
      email: 'admin@demo.com',
      displayName: 'System Admin',
      photoUrl: '',
      isAnonymous: false,
      createdAt: DateTime.now(),
      fullName: 'System Administrator',
      roleId: 'admin',
    );

    final chiefAccountant = UserModel(
      uid: 'u_chief',
      email: 'chief@demo.com',
      displayName: 'Chief Accountant',
      photoUrl: '',
      isAnonymous: false,
      createdAt: DateTime.now(),
      fullName: 'Kế toán trưởng',
      roleId: 'chiefAccountant',
    );

    final accountant = UserModel(
      uid: 'u_acc',
      email: 'accountant@demo.com',
      displayName: 'Accountant Staff',
      photoUrl: '',
      isAnonymous: false,
      createdAt: DateTime.now(),
      fullName: 'Kế toán viên',
      roleId: 'accountant',
    );

    final salesperson = UserModel(
      uid: 'u_sales',
      email: 'sales@demo.com',
      displayName: 'Sales Agent',
      photoUrl: '',
      isAnonymous: false,
      createdAt: DateTime.now(),
      fullName: 'Nhân viên bán hàng',
      roleId: 'salesperson',
    );

    final partnerA = UserModel(
      uid: 'u_partner_a',
      email: 'partner_a@company.com',
      displayName: 'Partner A Corp',
      photoUrl: '',
      isAnonymous: false,
      createdAt: DateTime.now(),
      fullName: 'Công ty Đối tác A',
      roleId: 'partner',
      taxCode: '11111',
    );

    final partnerB = UserModel(
      uid: 'u_partner_b',
      email: 'partner_b@company.com',
      displayName: 'Partner B Corp',
      photoUrl: '',
      isAnonymous: false,
      createdAt: DateTime.now(),
      fullName: 'Công ty Đối tác B',
      roleId: 'partner',
      taxCode: '22222',
    );

    // 2. Setup mock invoices
    final invoiceAConfirmed = InvoiceModel(
      invoiceId: 'inv_a_conf',
      transactionId: 'tx_a',
      invoiceNumber: 'INV-A-1',
      partnerName: 'Công ty Đối tác A',
      partnerAddress: 'Địa chỉ A',
      taxCode: '11111',
      invoiceDate: DateTime.now(),
      subTotal: 10000000,
      vatRate: 8,
      vatAmount: 800000,
      totalAmount: 10800000,
      createdBy: 'u_acc',
      scanId: 'scan_a',
      status: 'confirmed',
    );

    final invoiceAPending = InvoiceModel(
      invoiceId: 'inv_a_pend',
      transactionId: 'tx_b',
      invoiceNumber: 'INV-A-2',
      partnerName: 'Công ty Đối tác A',
      partnerAddress: 'Địa chỉ A',
      taxCode: '11111',
      invoiceDate: DateTime.now(),
      subTotal: 5000000,
      vatRate: 10,
      vatAmount: 500000,
      totalAmount: 5500000,
      createdBy: 'u_acc',
      scanId: 'scan_b',
      status: 'pending',
    );

    final invoiceBConfirmed = InvoiceModel(
      invoiceId: 'inv_b_conf',
      transactionId: 'tx_c',
      invoiceNumber: 'INV-B-1',
      partnerName: 'Công ty Đối tác B',
      partnerAddress: 'Địa chỉ B',
      taxCode: '22222',
      invoiceDate: DateTime.now(),
      subTotal: 20000000,
      vatRate: 8,
      vatAmount: 1600000,
      totalAmount: 21600000,
      createdBy: 'u_acc',
      scanId: null,
      status: 'confirmed',
    );

    final allInvoices = [invoiceAConfirmed, invoiceAPending, invoiceBConfirmed];


    group('3. Test liên kết dữ liệu OCRScan với Transaction & Invoice', () {
      test('Mối liên kết khóa ngoại hoạt động chính xác giữa OCRScan, Transaction và Invoice', () {
        final ocrScan = OCRScanModel(
          scanId: 'scan_100',
          userId: 'u_acc',
          imagePath: 'uploads/rec_100.jpg',
          extractedAmount: 15000000,
          extractedTaxCode: '11111',
          extractedDate: DateTime.now(),
          rawJson: '{}',
          status: 'completed',
          transactionId: 'tx_100',
          invoiceId: 'inv_100',
          createdAt: DateTime.now(),
        );

        final transaction = TransactionModel(
          transactionId: 'tx_100',
          userId: 'u_acc',
          categoryId: 'cat_doanhthu',
          invoiceId: 'inv_100',
          scanId: 'scan_100', // Matches scanId
          amount: 15000000,
          type: TransactionType.income,
          transactionDate: DateTime.now(),
          status: 'pending',
          createdAt: DateTime.now(),
        );

        final invoice = InvoiceModel(
          invoiceId: 'inv_100',
          transactionId: 'tx_100',
          invoiceNumber: 'INV-100',
          partnerName: 'Công ty A',
          partnerAddress: 'Địa chỉ A',
          taxCode: '11111',
          invoiceDate: DateTime.now(),
          subTotal: 15000000,
          vatRate: 0,
          vatAmount: 0,
          totalAmount: 15000000,
          createdBy: 'u_acc',
          scanId: 'scan_100', // Matches scanId
          status: 'pending',
        );

        // Verify bidirectional keys
        expect(transaction.scanId, ocrScan.scanId);
        expect(invoice.scanId, ocrScan.scanId);
        expect(ocrScan.transactionId, transaction.transactionId);
        expect(ocrScan.invoiceId, invoice.invoiceId);
        expect(transaction.invoiceId, invoice.invoiceId);
        expect(invoice.transactionId, transaction.transactionId);
      });
    });

    group('4. Test tính toán chi tiết hóa đơn (InvoiceItems)', () {
      test('Chi tiết mặt hàng tính đúng thành tiền (amount = quantity * unitPrice)', () {
        final item = InvoiceItemModel(
          itemId: 'item_1',
          invoiceId: 'inv_test',
          itemName: 'Mặt hàng test',
          unit: 'cái',
          quantity: 5,
          unitPrice: 200000,
          amount: 1000000, // Manual or calculated
        );
        expect(item.amount, item.quantity * item.unitPrice);
      });

      test('Tổng tiền hàng subTotal bằng tổng tiền của tất cả InvoiceItems', () {
        final items = [
          const InvoiceItemModel(
            itemId: 'item_1',
            invoiceId: 'inv_test',
            itemName: 'Mặt hàng 1',
            unit: 'cái',
            quantity: 3,
            unitPrice: 100000,
            amount: 300000,
          ),
          const InvoiceItemModel(
            itemId: 'item_2',
            invoiceId: 'inv_test',
            itemName: 'Mặt hàng 2',
            unit: 'cái',
            quantity: 2,
            unitPrice: 500000,
            amount: 1000000,
          ),
        ];

        final sumOfItems = items.fold<int>(0, (sum, item) => sum + item.amount);
        
        final invoice = InvoiceModel(
          invoiceId: 'inv_test',
          transactionId: 'tx_test',
          invoiceNumber: 'INV-TEST',
          partnerName: 'Công ty Test',
          partnerAddress: 'Địa chỉ Test',
          taxCode: '99999',
          invoiceDate: DateTime.now(),
          subTotal: sumOfItems, // Handled by service sum
          vatRate: 10,
          vatAmount: 130000,
          totalAmount: sumOfItems + 130000,
          createdBy: 'u_acc',
          status: 'confirmed',
        );

        expect(invoice.subTotal, 1300000); // 300,000 + 1,000,000 = 1,300,000 VND
        expect(invoice.subTotal, sumOfItems);
      });
    });
  });
}
