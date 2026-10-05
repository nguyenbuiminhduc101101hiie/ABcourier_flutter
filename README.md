# ABFreight — Hệ thống quản lý Freight Forwarding

> Phần mềm web quản lý nghiệp vụ giao nhận vận tải của ABFreight: báo giá, booking, chứng từ lô hàng (SI, HBL, A/N, eDO), container, đề nghị thanh toán – tạm ứng, công nợ, hóa đơn điện tử và thu chi — kết nối với nền tảng chuyển phát nhanh **ABCourier**.

ABFreight dùng chung khung kiến trúc với họ sản phẩm NVOCC (**NVOAMASIS**, **NVOPASL**, **NVOVSSA**, **NVOVSSL**, **DNX**) nhưng là bản cấu hình riêng cho ABFreight (database `ABfreight`), tập trung vào nghiệp vụ forwarding và tích hợp mảng Courier.

---

## 1. Hệ thống dùng để làm gì?

| Phòng ban | Công việc trên hệ thống |
|---|---|
| **Sales / Pricing** | Bảng giá cước xuất/nhập, trucking, KTCL, thủ tục hải quan, biểu giá nâng hạ / rút ruột / lưu kho / KDTV, LCC; nhận yêu cầu báo giá (RFQ), gửi báo giá cho khách |
| **Chứng từ / Operation** | Booking, Shipping Instruction (SI), xuất HBL, Arrival Notice, eDO, lệnh điều xe, lệnh cấp container rỗng, cam kết mượn cont trả rỗng, yêu cầu trucking / thủ tục hải quan / C/O |
| **Quản lý container (EQ)** | Container tracking, EQ control, terminal, tồn kho, barem trọng lượng container, Tariff header/tier, Shipment charge context |
| **Kế toán công nợ** | Đề nghị thanh toán (DNTT), tạm ứng (DNTU) và luồng duyệt, tổng hợp công nợ, công nợ đến hạn, xuất Debit/Credit note, báo cáo thanh toán |
| **Hóa đơn & quỹ** | Phát hành hóa đơn điện tử **BKAV**, **Viettel**; phiếu thu, phiếu chi, phiếu kế toán, báo cáo quỹ tiền mặt, sổ nhật ký chung, số dư khách hàng, hạch toán khấu hao TSCĐ |
| **Ban giám đốc** | Lợi nhuận theo lô, báo cáo shipment / khách hàng / pricing / phí, thống kê sản lượng, HBL report |
| **Courier** | Menu **11. Courier** mở hệ thống chuyển phát nhanh ABCourier (`courier.abfreight.vn`) và Rate Hub |
| **Toàn công ty** | Thông báo realtime, trợ lý AI hỏi đáp dữ liệu, lịch sử thao tác, phân quyền theo menu, đăng nhập QR, duyệt phiếu thu chi trên app mobile |

## 2. Các phân hệ chính

Menu chia theo nhóm, mỗi màn hình mở thành **tab** trong ứng dụng:

1. **System** – Người dùng, phân quyền, danh mục (cảng, phí, Ref No, trạng thái), thông tin công ty, danh mục tài khoản, nhật ký thao tác, chấm công, báo lỗi, hướng dẫn sử dụng.
2. **Business management** – Shipment, khách hàng / nhà cung cấp / đối tác, lợi nhuận.
3. **Report** – Báo cáo RFQ, báo giá, tạm ứng/hoàn ứng, shipment, khách hàng, pricing, phí.
4. **Pricing & Price schedule** – Lịch tàu, giá xuất/nhập, trucking, KTCL, thủ tục hải quan, LCC, các biểu giá dịch vụ.
5. **Payment & Payment request** – DNTT, DNTU, duyệt DNTT, công nợ, Debit/Credit note, hóa đơn (BKAV, Viettel), sổ nhật ký chung.
6. **Task** – Booking, HBL, A/N, eDO, lệnh điều xe, lệnh cấp rỗng, trucking, thủ tục hải quan, container tracking, báo cáo thống kê lô hàng.
7. **EQ** – EQ control, terminal, loại phí, tariff, tồn kho.
8. **Quản lý dòng tiền** – Phiếu thu, phiếu chi, phiếu kế toán, báo cáo quỹ, số dư khách hàng, hạch toán khấu hao.
9. **Courier** – Liên kết LMS Courier & Rate Hub.

## 3. Công nghệ sử dụng

| Hạng mục | Công nghệ |
|---|---|
| Nền tảng | **.NET 8**, **Blazor Server** (Interactive Server, render mode global) |
| Giao diện | MudBlazor 6, CodeBeam.MudBlazor.Extensions, Blazor.Bootstrap, Chart.js |
| Dữ liệu | **SQL Server**, Entity Framework Core 8, SQL Server distributed cache |
| Xác thực | Cookie Authentication (web), JWT Bearer (API mobile), Google Sign-In, đăng nhập QR, BCrypt |
| Realtime | SignalR (`/notificationhub`) |
| Báo cáo / in ấn | Stimulsoft Reports (Blazor), ClosedXML, EPPlus, OpenXML, ExcelDataReader, QRCoder, PdfPig, RazorLight |
| Tích hợp ngoài | Hóa đơn điện tử **BKAV**, **Viettel**; **Firebase Cloud Messaging** (push mobile); SMTP (MailKit); **OpenAI** (trợ lý AI) |
| Đa ngôn ngữ | Bản dịch lưu trong DB (`LocalizationResources`): `vi-VN`, `en-US`, `zh-CN` |
| Triển khai | IIS (hosting OutOfProcess, `web.config` tùy chỉnh) |

## 4. Kiến trúc tổng quan

```text
Trình duyệt ──(SignalR / Blazor Server)──► ABFreight (ASP.NET Core 8)
App mobile ──(REST + JWT)──────────────►   ├─ Components/   Giao diện Blazor theo từng phân hệ
                                           ├─ Controllers/  API: mobile, duyệt phiếu, upload, QR, file đính kèm
                                           ├─ Services/     Nghiệp vụ (booking, chứng từ, công nợ, hóa đơn, AI…)
                                           ├─ Hubs/         SignalR NotificationHub
                                           └─ Data/         AppDbContext
                                                   │
                                                   ▼
                                         SQL Server: ABfreight  ◄── dùng chung với CourierApi (bảng ABCourier)
                                                   │
                     BKAV / Viettel e-Invoice ◄────┼────► FCM, SMTP, OpenAI
```

Hệ thống chuyển phát nhanh liên quan:

- Frontend Flutter: [ABCourier](https://github.com/duclogisticssoftware/ABCourier)
- Backend API: [BackEnd_ABcourier](https://github.com/duclogisticssoftware/BackEnd_ABcourier)

## 5. Cấu trúc thư mục

```text
Components/      Trang Blazor, mỗi phân hệ một thư mục (Booking, SI, ExportHBL, PhieuThu, Invoice_BKAV…)
  Layout/        MainLayout, NavMenu (menu + phân quyền), DynamicTabs
Controllers/     API controller (mobile, duyệt phiếu, upload, QR login, attachment…)
Services/        Service nghiệp vụ, đăng ký DI trong Program.cs
Data/            AppDbContext, migrations
Models/          Entity & view model
Hubs/            SignalR hub
Resources/       Resource đa ngôn ngữ
Scripts/         Script SQL: tạo/sửa bảng, thêm quyền menu, import bản dịch
Secrets/         File service account Firebase (không commit — xem *.example)
docs/            Tài liệu (FCM, duyệt phiếu thu chi, app mobile)
wwwroot/         Static file, mẫu Excel/báo cáo
```

## 6. Chạy dự án

**Yêu cầu:** .NET 8 SDK, SQL Server, Visual Studio 2022 (khuyến nghị).

1. Cấu hình `appsettings.json` (hoặc `appsettings.Development.json`):

   | Section | Ý nghĩa |
   |---|---|
   | `ConnectionStrings:DefaultConnection` | Database nghiệp vụ |
   | `JwtSettings` | Khóa ký token cho API mobile |
   | `Smtp` | Gửi email |
   | `BkavInvoice`, `Fcm`, `ChatGPT` | Thông tin tích hợp bên ngoài |

   Đặt file `Secrets/firebase-service-account.json` (theo mẫu `.example`) nếu dùng push notification.

   > ⚠️ Không commit mật khẩu, API key thật lên git — dùng User Secrets hoặc biến môi trường.

2. Chuẩn bị database: chạy các script cần thiết trong `Scripts/`.

3. Chạy:

   ```bash
   dotnet run --project ABFreight.csproj --launch-profile http
   ```

   Mặc định: <http://localhost:5070> (profile `https`: <https://localhost:7248>).

## 7. Publish & triển khai

```bash
dotnet publish ABFreight.csproj -c Release -o ./publish
```

Copy thư mục `publish` lên IIS (giữ `web.config` tùy chỉnh). Khi bản mới có thay đổi DB, chạy script SQL tương ứng trong `Scripts/` **trước** khi chép code.
