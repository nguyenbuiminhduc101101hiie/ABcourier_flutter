@echo off
REM Chay file nay TREN SERVER IIS (CMD Run as Administrator)
REM Thu muc: C:\inetpub\wwwroot\abfreight

cd /d C:\inetpub\wwwroot\abfreight

echo ==== Folder contents ====
dir /b ABFreight.dll ABFreight.runtimeconfig.json ABFreight.deps.json appsettings.json web.config 2>nul

echo.
echo ==== Dotnet info ====
where dotnet
dotnet --list-runtimes
dotnet --info

echo.
echo ==== Try start app (Ctrl+C to stop) ====
set ASPNETCORE_ENVIRONMENT=Production
set ASPNETCORE_URLS=http://127.0.0.1:5089
dotnet ABFreight.dll

pause
