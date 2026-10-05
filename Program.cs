using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.SqlServer;
using Microsoft.Extensions.Localization;
using Microsoft.IdentityModel.Tokens;
using MudBlazor.Services;
using MudExtensions.Services;
using ABFreight.Components;
using ABFreight.Data;
using ABFreight.Hubs;
using ABFreight.Interface;
using ABFreight.Models;
using ABFreight.Options;
using ABFreight.Services;
using ABFreight.Services.Accounting;
using ABFreight.Services.Accounting.ExcelImport;
using ABFreight.Services.Localization;
using ABFreight.Services.MultiTenant;
using Stimulsoft.Drawing;
using System.Text;

static void WriteStartupLog(string message)
{
    try
    {
        var path = Path.Combine(AppContext.BaseDirectory, "startup.log");
        File.AppendAllText(path, $"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff} {message}{Environment.NewLine}");
    }
    catch
    {
        // Ignore logging failures during bootstrap.
    }
}

WriteStartupLog($"Boot start. BaseDirectory={AppContext.BaseDirectory}");

try
{
    // License Stimulsoft phải gán TRƯỚC mọi API Stimulsoft khác (kể cả GraphicsEngine).
    StimulsoftLicenseHelper.EnsureApplied();
    WriteStartupLog("Stimulsoft license step completed.");
}
catch (Exception ex)
{
    WriteStartupLog("Stimulsoft license step FAILED: " + ex);
    throw;
}

var builder = WebApplication.CreateBuilder(args);
WriteStartupLog($"WebApplication builder created. Environment={builder.Environment.EnvironmentName}");

builder.Services.AddLocalization();

// Register custom database-based string localizer factory
// This replaces the default file-based localization with database-driven localization
// Resources are loaded from LocalizationResources table and cached per culture
builder.Services.AddSingleton<IStringLocalizerFactory, DbStringLocalizerFactory>();

try
{
    // Avoid SixLabors.Fonts API mismatch with ClosedXML by using GDI text measurement on Windows
    Graphics.GraphicsEngine = GraphicsEngine.Gdi;
    WriteStartupLog("GraphicsEngine.Gdi assigned.");
}
catch (Exception ex)
{
    WriteStartupLog("GraphicsEngine.Gdi FAILED: " + ex);
    throw;
}

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents()
    .AddCircuitOptions(options =>
    {
        // Enable to see Blazor circuit exception details when debugging (disable in production for security)
        options.DetailedErrors = builder.Configuration.GetValue<bool>("DetailedErrors");
    });

builder.Services.AddMudServices();
builder.Services.AddControllers();
builder.Services.AddHttpClient();
builder.Services.AddMemoryCache();

// Distributed cache (SQL Server) - token D/O QR và dữ liệu cache khác sống qua restart
builder.Services.AddDistributedSqlServerCache(options =>
{
    options.ConnectionString = builder.Configuration.GetConnectionString("DefaultConnection");
    options.SchemaName = "dbo";
    options.TableName = "DistributedCache";
});

// Cookie auth keys must survive IIS app-pool recycle / republish,
// otherwise the login cookie cannot be decrypted and the user looks "logged out".
// Prefer ContentRoot/Keys; fall back to LocalAppData if IIS app-pool cannot write the site folder.
var dataProtectionKeysPath = Path.Combine(builder.Environment.ContentRootPath, "Keys");
try
{
    Directory.CreateDirectory(dataProtectionKeysPath);
}
catch (Exception ex)
{
    WriteStartupLog("Keys under ContentRoot failed: " + ex.Message);
    dataProtectionKeysPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "ABFreight",
        "DataProtection-Keys");
    try
    {
        Directory.CreateDirectory(dataProtectionKeysPath);
    }
    catch (Exception ex2)
    {
        // Last resort: temp folder so startup never dies on IIS AppPoolIdentity permissions.
        dataProtectionKeysPath = Path.Combine(Path.GetTempPath(), "ABFreight-DataProtection-Keys");
        Directory.CreateDirectory(dataProtectionKeysPath);
        WriteStartupLog("Keys fallback to Temp: " + ex2.Message);
    }
}

WriteStartupLog("DataProtection keys path: " + dataProtectionKeysPath);
builder.Services.AddDataProtection()
    .PersistKeysToFileSystem(new DirectoryInfo(dataProtectionKeysPath))
    .SetApplicationName("ABFreight");

//# for BLAZOR COOKIE Auth
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<CustomAuthenticationStateProvider>();
builder.Services.AddScoped<AuthenticationStateProvider>(sp =>
    sp.GetRequiredService<CustomAuthenticationStateProvider>());
builder.Services.AddCascadingAuthenticationState();
builder.Services.AddMudExtensions();
builder.Services.AddBlazorBootstrap();

//## for BLAZOR COOKIE Auth
/// ref — https://blazorhelpwebsite.com/ViewBlogPost/36
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(cfg =>
    {
        cfg.LoginPath = "/Account/Login";
        cfg.LogoutPath = "/Account/Logout";
        cfg.Cookie.Name = ".ABFreight.Cookies";
        cfg.Cookie.Path = "/";
        cfg.Cookie.SameSite = SameSiteMode.Lax;
        cfg.Cookie.HttpOnly = true;
        // Site is HTTPS (abfreight.nvocc.vn). Always mark auth cookie Secure so browsers keep it.
        cfg.Cookie.SecurePolicy = CookieSecurePolicy.Always;
        cfg.ExpireTimeSpan = TimeSpan.FromDays(30);
        cfg.SlidingExpiration = true;
    })
    .AddJwtBearer(JwtBearerDefaults.AuthenticationScheme, options =>
    {
        var jwt = builder.Configuration.GetSection("JwtSettings");
        var secret = jwt["SecretKey"] ?? throw new InvalidOperationException("JwtSettings:SecretKey missing");
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwt["Issuer"],
            ValidAudience = jwt["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret)),
            ClockSkew = TimeSpan.FromMinutes(2)
        };
        // SignalR: JWT từ query string access_token
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) &&
                    path.StartsWithSegments("/notificationhub"))
                {
                    context.Token = accessToken;
                }
                return Task.CompletedTask;
            }
        };
    });

builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection("JwtSettings"));
builder.Services.AddScoped<MobileJwtTokenService>();

//Setting
builder.Services.AddScoped<ITenantContext, TenantContext>();
builder.Services.AddDbContext<RegistryDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("RegistryConnection") ??
        throw new InvalidOperationException("RegistryConnection is not configured")));
builder.Services.AddScoped<TenantDatabaseProvisioningService>();
builder.Services.AddScoped<TenantAuthService>();
builder.Services.AddScoped<TenantLoginQrService>();

builder.Services.AddDbContext<AppDbContext>((serviceProvider, options) =>
{
    var configuration = serviceProvider.GetRequiredService<IConfiguration>();
    string? connectionString;

    // MultiTenant:Enabled=false → luôn dùng DB gốc (DefaultConnection).
    if (!configuration.GetValue("MultiTenant:Enabled", true))
    {
        connectionString = configuration.GetConnectionString("DefaultConnection");
    }
    else
    {
        var tenantContext = serviceProvider.GetRequiredService<ITenantContext>();
        tenantContext.EnsureInitializedFromHttpContext();
        connectionString = tenantContext.ConnectionString
            ?? configuration.GetConnectionString("DefaultConnection");
    }

    options.UseSqlServer(connectionString
        ?? throw new InvalidOperationException("Sorry, your connection is not found"));
});

builder.Services.AddSingleton<IDbContextFactory<AppDbContext>, TenantAwareDbContextFactory>();
builder.Services.AddScoped<AccountService>();
builder.Services.AddScoped<ReportServices>();
builder.Services.AddScoped<TrainScheduleServices>();
builder.Services.AddScoped<IUserService, UserServicecs>();
builder.Services.Configure<FormOptions>(options =>
{
    options.ValueLengthLimit = int.MaxValue;
    options.MultipartBodyLengthLimit = int.MaxValue;
    options.MultipartHeadersLengthLimit = int.MaxValue;
    options.BufferBodyLengthLimit = int.MaxValue;
});
builder.Services.AddScoped<SharedServices>();
builder.Services.AddScoped<CustomerService>();
builder.Services.AddScoped<BookingService>();
builder.Services.AddScoped<SupportServices>();
builder.Services.AddScoped<ShipmentService>();
builder.Services.AddScoped<ContainerDepotLookupService>();
builder.Services.AddScoped<InvoicePdfImportService>();
builder.Services.AddScoped<StockService>();
builder.Services.AddScoped<ExcelImportCrudService>();
builder.Services.AddScoped<DeliveryOrderQrService>();
builder.Services.AddScoped<ArrivalNoticeQrService>();
builder.Services.AddScoped<HblQrService>();
builder.Services.AddScoped<QuotationService>();
builder.Services.AddScoped<EmailService>();
builder.Services.AddScoped<FontService>();
builder.Services.AddScoped<GlobalServices>();
builder.Services.AddScoped<BillSeaLayoutFormService>();
builder.Services.AddScoped<ProductPriceServices>();
builder.Services.AddScoped<LocalChargesServices>();
builder.Services.AddScoped<LenhDieuXeServices>();
builder.Services.AddScoped<YeuCauTruckingServices>();
builder.Services.AddScoped<TKHQ_Services>();
builder.Services.AddScoped<ThuTucTuVanHQ_Services>();
builder.Services.AddScoped<Bieugianangha_Services>();
builder.Services.AddScoped<DNTUServices>();
builder.Services.AddScoped<PhieuThu_Chi_Services>();
builder.Services.AddScoped<PhieuApproveService>();
builder.Services.Configure<FcmOptions>(builder.Configuration.GetSection("Fcm"));
builder.Services.AddHttpClient(nameof(FcmPushService));
builder.Services.AddScoped<FcmPushService>();
builder.Services.AddScoped<Danhmuctaikhoan_services>();
builder.Services.AddScoped<TaxServices>();
builder.Services.Configure<BkavInvoiceSettings>(builder.Configuration.GetSection("BkavInvoice"));
builder.Services.AddHttpClient<BkavInvoiceService>();
builder.Services.AddScoped<ExportCostPriceServices>();
builder.Services.AddScoped<IssueReportServices>();
builder.Services.AddSignalR();
builder.Services.AddSingleton<IUserIdProvider, CustomUserIdProvider>();
builder.Services.AddScoped<NotificationService>();
builder.Services.AddScoped<tigiaVCBservices>();
builder.Services.AddScoped<AttendanceService>();
builder.Services.AddScoped<InventoryExportService>();
builder.Services.AddScoped<IClientIpService, ClientIpService>();
builder.Services.AddScoped<IWordDocumentService, WordDocumentService>();
builder.Services.AddScoped<LeaveRequestService>();
builder.Services.AddScoped<ResxImportService>();
builder.Services.AddScoped<ThemeService>();
builder.Services.AddScoped<IFixedAssetService, FixedAssetService>();
builder.Services.AddScoped<IFixedAssetDepreciationService, FixedAssetDepreciationService>();

// Forwarded headers (X-Forwarded-For / X-Forwarded-Proto) support for IIS / reverse proxy
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});

builder.Services.AddScoped<IForgotPasswordEmailService, ForgotPasswordEmailService>();

// AI Assistant - ChatGPT integration
builder.Services.Configure<ABFreight.Models.ChatGPTSettings>(builder.Configuration.GetSection("ChatGPT"));
builder.Services.AddHttpClient<ABFreight.Services.ChatGPTService>();
builder.Services.AddScoped<ABFreight.Services.ChatGPTService>();
builder.Services.AddHttpClient<ABFreight.Services.WebSearchService>();
builder.Services.AddScoped<ABFreight.Services.WebSearchService>();



builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

builder.Services.AddHttpClient<HistoryLogService>((serviceProvider, client) =>
{
    var config = serviceProvider.GetRequiredService<IConfiguration>();
    var env = serviceProvider.GetRequiredService<IWebHostEnvironment>();

    string baseUrl;

    if (env.IsDevelopment())
    {
        // D�ng URL local khi ?ang ch?y local
        baseUrl = "http://localhost:5070/";
    }
    else
    {
        // D�ng URL th?t khi publish l�n server
        baseUrl = config["ApiSettings:HistoryLogBaseUrl"]; // may be null
        if (string.IsNullOrWhiteSpace(baseUrl))
        {
            // Fallback: keep existing or throw meaningful error
            baseUrl = "https://localhost/"; // safe fallback placeholder
        }
        //baseUrl = builder.Configuration["ApiSettings:HistoryLogBaseUrl"];
    }

    client.BaseAddress = new Uri(baseUrl!);
});

builder.Services.Configure<AccountBalanceImportOptions>(
    builder.Configuration.GetSection(AccountBalanceImportOptions.SectionName));

builder.Services.AddScoped<
    IAccountBalanceExcelImportService,
    AccountBalanceExcelImportService>();


builder.Services.AddDbContextFactory<AppDbContext>(options =>
{
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"));
});


// Change SingletonSerivce to scoped to align with per-request auth/user context and avoid holding onto stale user/context state.
builder.Services.AddScoped<SingletonSerivce>();

try
{
    WriteStartupLog("Building application host...");
    var app = builder.Build(); //--------------------------------------------------
    WriteStartupLog("Application host built.");

var supportedCultures = new[] { "en-US", "vi-VN", "zh-CN" };
var localizationOptions = new RequestLocalizationOptions()
    .SetDefaultCulture(supportedCultures[0])
    .AddSupportedCultures(supportedCultures)
    .AddSupportedUICultures(supportedCultures);
app.UseRequestLocalization(localizationOptions);

// Configure the HTTP request pipeline.
var disableHttpsRedirection = builder.Configuration.GetValue("DisableHttpsRedirection", false);
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    if (!disableHttpsRedirection)
    {
        // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
        app.UseHsts();
    }
}

// MUST appear early, before HTTPS/auth middleware that reads scheme or RemoteIpAddress
app.UseForwardedHeaders();

// HTTP-only IIS sites: set "DisableHttpsRedirection": true in appsettings to avoid login cookie loss.
if (!disableHttpsRedirection)
{
    app.UseHttpsRedirection();
}

app.UseStaticFiles();
app.UseAntiforgery();
app.UseCors();
//# for BLAZOR COOKIE Auth
app.UseAuthentication();
app.UseMiddleware<TenantMiddleware>();
app.UseAuthorization();

app.MapHub<NotificationHub>("/notificationhub");

/// ref��https://learn.microsoft.com/zh-tw/aspnet/core/fundamentals/error-handling?view=aspnetcore-8.0#usestatuscodepages
// Map API controllers BEFORE status code pages to avoid redirects
app.MapControllers();

// API (/api/*): trả JSON khi 404/401/... — không redirect HTML /ErrorStatus (Flutter cần JSON)
app.UseWhen(
    ctx => ctx.Request.Path.StartsWithSegments("/api"),
    apiBranch =>
    {
        apiBranch.UseStatusCodePages(async statusCodeContext =>
        {
            var http = statusCodeContext.HttpContext;
            if (http.Response.HasStarted) return;
            http.Response.ContentType = "application/json; charset=utf-8";
            var code = http.Response.StatusCode;
            var payload = System.Text.Json.JsonSerializer.Serialize(new
            {
                flag = false,
                message = code switch
                {
                    401 => "Unauthorized.",
                    403 => "Forbidden.",
                    404 => "API endpoint not found.",
                    _ => $"HTTP {code}"
                },
                status = code
            });
            await http.Response.WriteAsync(payload);
        });
    });

// Non-API (Blazor): giữ redirect ErrorStatus như cũ
app.UseWhen(
    ctx => !ctx.Request.Path.StartsWithSegments("/api"),
    nonApi => nonApi.UseStatusCodePagesWithRedirects("/ErrorStatus/{0}"));

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

    WriteStartupLog("Starting web host (app.Run)...");
    app.Run();
}
catch (Exception ex)
{
    WriteStartupLog("FATAL startup exception: " + ex);
    throw;
}
