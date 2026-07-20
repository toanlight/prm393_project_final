# Nhật ký các thay đổi đã thực hiện

## Mục tiêu

Xây dựng và hoàn thiện phân hệ **Hóa đơn (Invoice)** cho dự án
SmartFinance, đồng thời giữ tương thích với kiến trúc hiện tại.

## Đã thực hiện

-   Phân tích kiến trúc Router, Provider, Repository, OCR, Transaction,
    Invoice.
-   Rà soát yêu cầu bài và điều chỉnh phạm vi.
-   Đề xuất rồi loại bỏ Dashboard/Module Invoice độc lập vì vượt yêu
    cầu.
-   Thiết kế lại luồng xem hóa đơn.
-   Phân tích lỗi Locale (`vi_VN`).
-   Phân tích lỗi Invoice không refresh sau khi scan.
-   Phân tích lỗi layout Invoice bị thưa và không đồng nhất với
    Transaction.
-   Tạo nhiều bản patch thử nghiệm để chỉnh giao diện và luồng.

## Các patch đã tạo

-   invoice_module_patch.zip
-   invoice_preview_redesign_patch.zip
-   invoice_direct_preview_patch.zip
-   invoice_refresh_layout_fix.zip
-   invoice_compact_table_fix.zip

## Việc còn lại

1.  Đồng bộ UI Invoice với Transaction.
2.  Refresh dữ liệu ngay sau khi tạo hóa đơn.
3.  Hoàn thiện ReceiptImagePreviewScreen.
4.  Kiểm thử Desktop/Mobile.