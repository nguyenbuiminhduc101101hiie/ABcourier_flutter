-- Dang ky database goc ABfreight vao ABFreight_Acc_Multi_DB
-- (tuy chon - app cung tu ghi khi login lan dau).
-- Doi @SqlUserId / @SqlPassword cho dung tai khoan SQL dung de vao ABfreight.
-- Script dung ten 3 phan nen chay duoc o bat ky database context nao.

DECLARE @DatabaseName NVARCHAR(128) = N'ABfreight';
DECLARE @SqlUserId    NVARCHAR(128) = N'sgn-fc-admin';
DECLARE @SqlPassword  NVARCHAR(512) = N'qwe123!@#';
DECLARE @ServerName   NVARCHAR(256) = N'logisticssoftware.vn';

IF OBJECT_ID(N'[ABFreight_Acc_Multi_DB].[dbo].[TenantDatabaseRegistry]', N'U') IS NULL
BEGIN
    RAISERROR(N'Chua co bang TenantDatabaseRegistry. Chay Create_Acc_Multi_DB_And_TenantRegistry.sql truoc.', 16, 1);
    RETURN;
END

IF NOT EXISTS (
    SELECT 1 FROM [ABFreight_Acc_Multi_DB].[dbo].[TenantDatabaseRegistry]
    WHERE DatabaseName = @DatabaseName)
BEGIN
    INSERT INTO [ABFreight_Acc_Multi_DB].[dbo].[TenantDatabaseRegistry]
        (TenantId, DatabaseName, ServerName, SqlUserId, SqlPassword, DisplayName, CreatedAtUtc, CreatedByAppUser, IsActive)
    VALUES
        (NEWID(), @DatabaseName, @ServerName, @SqlUserId, @SqlPassword, @DatabaseName, SYSUTCDATETIME(), N'manual-setup', 1);
END
GO
