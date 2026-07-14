import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/invoice_model.dart';

class InvoicePdfService {
  InvoicePdfService._();

  static Future<Uint8List> buildPdf({
    required InvoiceModel invoice,
    Uint8List? receiptImageBytes,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final document = pw.Document(
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      ),
    );

    final receiptImage = receiptImageBytes == null
        ? null
        : pw.MemoryImage(receiptImageBytes);

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Trang ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ),
        build: (context) => [
          _buildHeader(invoice),
          pw.SizedBox(height: 18),
          _buildSellerInformation(invoice),
          pw.SizedBox(height: 18),
          _buildPaymentSummary(invoice),
          if (receiptImage != null) ...[
            pw.SizedBox(height: 24),
            pw.Text(
              'Ảnh chứng từ',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 13,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              height: 320,
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Image(
                receiptImage,
                fit: pw.BoxFit.contain,
              ),
            ),
          ],
          pw.SizedBox(height: 24),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'Tài liệu được tạo từ phân hệ SmartFinance - OCR mô phỏng.',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _buildHeader(InvoiceModel invoice) {
    return pw.Column(
      children: [
        pw.Text(
          'HÓA ĐƠN GIÁ TRỊ GIA TĂNG',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Số hóa đơn: ${invoice.invoiceNumber ?? '—'}',
          style: const pw.TextStyle(fontSize: 11),
        ),
        pw.Text(
          'Ngày hóa đơn: ${_formatDate(invoice.invoiceDate)}',
          style: const pw.TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  static pw.Widget _buildSellerInformation(InvoiceModel invoice) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'THÔNG TIN ĐƠN VỊ BÁN',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pw.SizedBox(height: 10),
          _pdfLine('Tên đơn vị', invoice.partnerName ?? '—'),
          _pdfLine('Địa chỉ', invoice.partnerAddress ?? '—'),
          _pdfLine('Mã số thuế', invoice.taxCode ?? '—'),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentSummary(InvoiceModel invoice) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          _moneyRow('Tiền hàng', _formatMoney(invoice.subTotal)),
          _moneyRow(
            'Thuế suất VAT',
            '${invoice.vatRate.toStringAsFixed(0)}%',
          ),
          _moneyRow('Tiền VAT', _formatMoney(invoice.vatAmount)),
          pw.Container(
            color: PdfColors.blue50,
            child: _moneyRow(
              'TỔNG THANH TOÁN',
              _formatMoney(invoice.totalAmount),
              bold: true,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 92,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.Widget _moneyRow(
      String label,
      String value, {
        bool bold = false,
        double fontSize = 11,
      }) {
    final style = pw.TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String _formatMoney(int value) {
    return '${NumberFormat.decimalPattern('vi_VN').format(value)} VNĐ';
  }
}
