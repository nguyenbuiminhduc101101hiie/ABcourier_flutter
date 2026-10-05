-- =====================================================================
-- Bổ sung các cột còn thiếu (đồng bộ model từ NVOAMASIS26) - 2026-10-05
-- Chạy được nhiều lần (mỗi cột đều kiểm tra tồn tại trước khi thêm).
-- BẮT BUỘC chạy TRƯỚC khi deploy code mới.
-- =====================================================================
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;

-- ---------------------------------------------------------------------
-- 1. Credit: đã thanh toán + field import EOR
-- ---------------------------------------------------------------------
IF COL_LENGTH(N'dbo.Credit', N'dathanhtoan') IS NULL
    ALTER TABLE dbo.Credit ADD dathanhtoan bit NULL CONSTRAINT DF_Credit_dathanhtoan DEFAULT CAST(0 AS bit);
IF COL_LENGTH(N'dbo.Credit', N'EstNo') IS NULL
    ALTER TABLE dbo.Credit ADD EstNo nvarchar(max) NULL;
IF COL_LENGTH(N'dbo.Credit', N'Grade') IS NULL
    ALTER TABLE dbo.Credit ADD Grade nvarchar(max) NULL;
IF COL_LENGTH(N'dbo.Credit', N'DamageDetail') IS NULL
    ALTER TABLE dbo.Credit ADD DamageDetail nvarchar(max) NULL;
IF COL_LENGTH(N'dbo.Credit', N'Remark') IS NULL
    ALTER TABLE dbo.Credit ADD Remark nvarchar(max) NULL;

-- ---------------------------------------------------------------------
-- 2. Debit: đã thanh toán + liên kết phiếu thu
-- ---------------------------------------------------------------------
IF COL_LENGTH(N'dbo.Debit', N'dathanhtoan') IS NULL
    ALTER TABLE dbo.Debit ADD dathanhtoan bit NULL CONSTRAINT DF_Debit_dathanhtoan DEFAULT CAST(0 AS bit);
IF COL_LENGTH(N'dbo.Debit', N'PhieuthuID') IS NULL
    ALTER TABLE dbo.Debit ADD PhieuthuID uniqueidentifier NULL;

-- ---------------------------------------------------------------------
-- 3. HBL: hãng tàu
-- ---------------------------------------------------------------------
IF COL_LENGTH(N'dbo.HBL', N'Carrier') IS NULL
    ALTER TABLE dbo.HBL ADD Carrier nvarchar(max) NULL;

-- ---------------------------------------------------------------------
-- 4. Job: số Booking
-- ---------------------------------------------------------------------
IF COL_LENGTH(N'dbo.Job', N'BookingNo') IS NULL
    ALTER TABLE dbo.Job ADD BookingNo nvarchar(max) NULL;

-- ---------------------------------------------------------------------
-- 5. HoaDonDauRa: thu hộ + đã thanh toán
-- ---------------------------------------------------------------------
IF COL_LENGTH(N'dbo.HoaDonDauRa', N'thuho') IS NULL
    ALTER TABLE dbo.HoaDonDauRa ADD thuho bit NULL CONSTRAINT DF_HoaDonDauRa_thuho DEFAULT CAST(0 AS bit);
IF COL_LENGTH(N'dbo.HoaDonDauRa', N'dathanhtoan') IS NULL
    ALTER TABLE dbo.HoaDonDauRa ADD dathanhtoan bit NULL CONSTRAINT DF_HoaDonDauRa_dathanhtoan DEFAULT CAST(0 AS bit);

-- ---------------------------------------------------------------------
-- 6. HoaDonDauVao: thông tin từ XML hóa đơn điện tử
-- ---------------------------------------------------------------------
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'mausohoadon') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD mausohoadon nvarchar(50) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'kyhieuhoadon') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD kyhieuhoadon nvarchar(50) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'loaihoadon') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD loaihoadon nvarchar(255) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'hinhthucthanhtoan') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD hinhthucthanhtoan nvarchar(255) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'xmlDocId') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD xmlDocId nvarchar(100) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'tennguoiban') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD tennguoiban nvarchar(500) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'mstnguoiban') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD mstnguoiban nvarchar(50) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'diachinguoiban') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD diachinguoiban nvarchar(1000) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'tennguoimua') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD tennguoimua nvarchar(500) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'mstnguoimua') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD mstnguoimua nvarchar(50) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'diachinguoimua') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD diachinguoimua nvarchar(1000) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'tienthue') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD tienthue float NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'chietkhau') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD chietkhau float NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'tienbangchu') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD tienbangchu nvarchar(500) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'billno') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD billno nvarchar(100) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'vesselvoyage') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD vesselvoyage nvarchar(255) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'pol') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD pol nvarchar(255) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'pod') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD pod nvarchar(255) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'ghichu') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD ghichu nvarchar(max) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'nguonimport') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD nguonimport nvarchar(20) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'tenfile') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD tenfile nvarchar(500) NULL;
IF COL_LENGTH(N'dbo.HoaDonDauVao', N'xmlcontent') IS NULL
    ALTER TABLE dbo.HoaDonDauVao ADD xmlcontent nvarchar(max) NULL;

-- ---------------------------------------------------------------------
-- 7. Booking (CONTAINEROUTBOUNDNOTIFY_sale): POT bổ sung, TK20, Freight Payable
-- ---------------------------------------------------------------------
IF COL_LENGTH(N'dbo.CONTAINEROUTBOUNDNOTIFY_sale', N'hano_POT_Ext') IS NULL
    ALTER TABLE dbo.CONTAINEROUTBOUNDNOTIFY_sale ADD hano_POT_Ext nvarchar(max) NULL;
IF COL_LENGTH(N'dbo.CONTAINEROUTBOUNDNOTIFY_sale', N'TK20') IS NULL
    ALTER TABLE dbo.CONTAINEROUTBOUNDNOTIFY_sale ADD TK20 int NULL;
IF COL_LENGTH(N'dbo.CONTAINEROUTBOUNDNOTIFY_sale', N'Freight_Payable') IS NULL
    ALTER TABLE dbo.CONTAINEROUTBOUNDNOTIFY_sale ADD Freight_Payable nvarchar(max) NULL;

-- ---------------------------------------------------------------------
-- 8. Terminal: mã cảng Hải Phòng
-- ---------------------------------------------------------------------
IF COL_LENGTH(N'dbo.Terminal', N'Codeha') IS NULL
    ALTER TABLE dbo.Terminal ADD Codeha nvarchar(max) NULL;

COMMIT TRANSACTION;
GO

-- ---------------------------------------------------------------------
-- Index (chạy sau khi cột đã tồn tại)
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Debit_PhieuthuID' AND object_id = OBJECT_ID(N'dbo.Debit'))
    CREATE INDEX IX_Debit_PhieuthuID ON dbo.Debit (PhieuthuID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_HoaDonDauVao_xmlDocId' AND object_id = OBJECT_ID(N'dbo.HoaDonDauVao'))
    EXEC(N'CREATE INDEX IX_HoaDonDauVao_xmlDocId ON dbo.HoaDonDauVao (xmlDocId) WHERE xmlDocId IS NOT NULL');
GO

-- ---------------------------------------------------------------------
-- Kiểm tra: phải ra đủ 37 dòng
-- ---------------------------------------------------------------------
SELECT OBJECT_NAME(c.object_id) AS table_name, c.name AS column_name,
       TYPE_NAME(c.system_type_id) AS type_name, c.max_length, c.is_nullable
FROM sys.columns c
WHERE (c.object_id = OBJECT_ID(N'dbo.Credit') AND c.name IN (N'dathanhtoan', N'EstNo', N'Grade', N'DamageDetail', N'Remark'))
   OR (c.object_id = OBJECT_ID(N'dbo.Debit') AND c.name IN (N'dathanhtoan', N'PhieuthuID'))
   OR (c.object_id = OBJECT_ID(N'dbo.HBL') AND c.name = N'Carrier')
   OR (c.object_id = OBJECT_ID(N'dbo.Job') AND c.name = N'BookingNo')
   OR (c.object_id = OBJECT_ID(N'dbo.HoaDonDauRa') AND c.name IN (N'thuho', N'dathanhtoan'))
   OR (c.object_id = OBJECT_ID(N'dbo.HoaDonDauVao') AND c.name IN (
        N'mausohoadon', N'kyhieuhoadon', N'loaihoadon', N'hinhthucthanhtoan', N'xmlDocId',
        N'tennguoiban', N'mstnguoiban', N'diachinguoiban', N'tennguoimua', N'mstnguoimua',
        N'diachinguoimua', N'tienthue', N'chietkhau', N'tienbangchu', N'billno', N'vesselvoyage',
        N'pol', N'pod', N'ghichu', N'nguonimport', N'tenfile', N'xmlcontent'))
   OR (c.object_id = OBJECT_ID(N'dbo.CONTAINEROUTBOUNDNOTIFY_sale') AND c.name IN (N'hano_POT_Ext', N'TK20', N'Freight_Payable'))
   OR (c.object_id = OBJECT_ID(N'dbo.Terminal') AND c.name = N'Codeha')
ORDER BY table_name, column_name;
GO
