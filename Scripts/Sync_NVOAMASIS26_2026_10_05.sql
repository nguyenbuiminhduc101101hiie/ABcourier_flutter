-- Đồng bộ DB cho đợt sync code từ NVOAMASIS26 (05/10/2026).
-- BẮT BUỘC chạy phần 1 + 2 TRƯỚC khi deploy code mới (EF đọc 2 cột này ở mọi truy vấn MBL / TransactionTypeMappings).
-- Phần 3 + 4 là bản dịch (không bắt buộc); chạy xong: DbStringLocalizerFactory.ClearCache() hoặc khởi động lại app.
-- Có thể chạy lại nhiều lần an toàn.

-- ───────────── 1. MBL.Carrier (hãng tàu, lấy từ Booking theo MBL.Bkno) ─────────────
IF COL_LENGTH(N'dbo.MBL', N'Carrier') IS NULL
    ALTER TABLE dbo.MBL ADD Carrier nvarchar(max) NULL;
GO

-- Điền sẵn Carrier cho MBL cũ từ Booking (bản cập nhật mới nhất của mỗi số Booking).
UPDATE m
SET m.Carrier = bk.Carrier
FROM dbo.MBL m
CROSS APPLY (
    SELECT TOP 1 LTRIM(RTRIM(b.Carrier)) AS Carrier
    FROM dbo.CONTAINEROUTBOUNDNOTIFY_sale b
    WHERE b.BookingNo = LTRIM(RTRIM(m.Bkno))
      AND b.Carrier IS NOT NULL AND LTRIM(RTRIM(b.Carrier)) <> ''
    ORDER BY b.UpdateTime DESC
) bk
WHERE (m.Carrier IS NULL OR LTRIM(RTRIM(m.Carrier)) = '')
  AND m.Bkno IS NOT NULL AND LTRIM(RTRIM(m.Bkno)) <> '';
GO

-- ───────────── 2. TransactionTypeMappings.AmountSource ─────────────
-- TOTAL (sau thuế) / NET (trước thuế) / TAX (thuế) / MANUAL (nhập tay). NULL = hệ thống tự đề xuất.
IF COL_LENGTH(N'dbo.TransactionTypeMappings', N'AmountSource') IS NULL
    ALTER TABLE dbo.TransactionTypeMappings ADD AmountSource nvarchar(10) NULL;
GO

-- ───────────── 3. Bản dịch màn 2.4.2 Báo cáo lô hàng (ghi đè nếu đã có) ─────────────
;WITH src (ResourceKey, Culture, Value) AS (
    SELECT * FROM (VALUES
    ('Rpt242_ActualDeliveryDate','vi-VN',N'Ngày giao (ADD)'),('Rpt242_ActualDeliveryDate','en-US',N'Actual Delivery (ADD)'),('Rpt242_ActualDeliveryDate','zh-CN',N'实际交付日期 (ADD)'),
    ('Rpt242_DateRangeHint','vi-VN',N'Lọc theo Date Report của HBL'),('Rpt242_DateRangeHint','en-US',N'Filtered by HBL Date Report'),('Rpt242_DateRangeHint','zh-CN',N'按 HBL 报告日期 (Date Report) 筛选'),
    ('Rpt242_EInvoiceNo','vi-VN',N'Số HĐ online'),('Rpt242_EInvoiceNo','en-US',N'E-Invoice No.'),('Rpt242_EInvoiceNo','zh-CN',N'电子发票号'),
    ('Rpt242_ReceiptNo','vi-VN',N'Số phiếu thu'),('Rpt242_ReceiptNo','en-US',N'Receipt No.'),('Rpt242_ReceiptNo','zh-CN',N'收款单号'),
    ('Rpt242_PaymentNo','vi-VN',N'Số phiếu chi'),('Rpt242_PaymentNo','en-US',N'Payment No.'),('Rpt242_PaymentNo','zh-CN',N'付款单号'),
    ('Rpt242_Agent','vi-VN',N'Agent'),('Rpt242_Agent','en-US',N'Agent'),('Rpt242_Agent','zh-CN',N'代理'),
    ('Rpt242_CargoKind','vi-VN',N'Loại hàng'),('Rpt242_CargoKind','en-US',N'Freight / NVOCC'),('Rpt242_CargoKind','zh-CN',N'货物类型'),
    ('Rpt242_CreditParties','vi-VN',N'Đối tượng Credit'),('Rpt242_CreditParties','en-US',N'Credit Parties'),('Rpt242_CreditParties','zh-CN',N'应付对象'),
    ('Rpt242_ProfitNvocc','vi-VN',N'Profit NVOCC'),('Rpt242_ProfitNvocc','en-US',N'Profit NVOCC'),('Rpt242_ProfitNvocc','zh-CN',N'NVOCC 利润'),
    ('Rpt242_Carrier','vi-VN',N'Carrier'),('Rpt242_Carrier','en-US',N'Carrier'),('Rpt242_Carrier','zh-CN',N'承运人'),
    ('Rpt242_BookingNo','vi-VN',N'Số Booking'),('Rpt242_BookingNo','en-US',N'Booking No.'),('Rpt242_BookingNo','zh-CN',N'订舱号')
    ) v (ResourceKey, Culture, Value)
)
MERGE dbo.LocalizationResources AS tgt
USING src
ON tgt.ResourceKey = src.ResourceKey AND tgt.Culture = src.Culture
WHEN MATCHED THEN
    UPDATE SET Value = src.Value
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ResourceKey, Culture, Value) VALUES (src.ResourceKey, src.Culture, src.Value);
GO

-- ───────────── 4. Bản dịch màn Customer / Vendor / Partner list (chỉ thêm nếu chưa có) ─────────────
;WITH src (ResourceKey, Culture, Value) AS (
    SELECT * FROM (VALUES
    ('CannotEditNomi','en-US',N'You cannot edit Sale Name ''NOMI''. Move the customer and try again.'),('CannotEditNomi','vi-VN',N'Không thể sửa Sale Name ''NOMI''. Hãy Move Customer rồi thử lại.'),('CannotEditNomi','zh-CN',N'无法编辑 Sale Name ''NOMI''。请移动客户后重试。'),
    ('Customer_EditTitle','en-US',N'Customer - Edit {0}'),('Customer_EditTitle','vi-VN',N'Customer - Edit {0}'),('Customer_EditTitle','zh-CN',N'客户 - 编辑 {0}'),
    ('ImportExcel','en-US',N'Import Excel'),('ImportExcel','vi-VN',N'Import Excel'),('ImportExcel','zh-CN',N'导入 Excel'),
    ('ImportPartnerListExcel','en-US',N'Import Partner List Excel'),('ImportPartnerListExcel','vi-VN',N'Import Partner List Excel'),('ImportPartnerListExcel','zh-CN',N'导入合作伙伴列表 Excel'),
    ('SearchContent','en-US',N'Search content'),('SearchContent','vi-VN',N'Nội dung tìm kiếm'),('SearchContent','zh-CN',N'搜索内容'),
    ('SearchBy','en-US',N'Search by'),('SearchBy','vi-VN',N'Tìm theo'),('SearchBy','zh-CN',N'搜索方式'),
    ('InvoiceName','en-US',N'Invoice name'),('InvoiceName','vi-VN',N'Tên Invoice'),('InvoiceName','zh-CN',N'发票名称'),
    ('DebitName','en-US',N'Debit name'),('DebitName','vi-VN',N'Tên Debit'),('DebitName','zh-CN',N'借记名称'),
    ('ShortName','en-US',N'Short name'),('ShortName','vi-VN',N'Tên viết tắt'),('ShortName','zh-CN',N'简称')
    ) v (ResourceKey, Culture, Value)
)
INSERT INTO dbo.LocalizationResources (ResourceKey, Culture, Value)
SELECT s.ResourceKey, s.Culture, s.Value
FROM src s
WHERE NOT EXISTS (SELECT 1 FROM dbo.LocalizationResources t WHERE t.ResourceKey = s.ResourceKey AND t.Culture = s.Culture);
GO

PRINT N'Sync_NVOAMASIS26_2026_10_05: done.';
