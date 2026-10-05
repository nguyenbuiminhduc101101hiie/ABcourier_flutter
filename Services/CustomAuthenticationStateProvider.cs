using Microsoft.AspNetCore.Components.Authorization;
using System.Security.Claims;

namespace ABFreight.Services;

/// <summary>
/// Cookie auth for Blazor Server/Interactive:
/// IIS/circuit often has null HttpContext after the circuit starts.
/// IHostEnvironmentAuthenticationStateProvider receives the host auth state
/// (from the cookie on the initial HTTP request) and keeps it for the circuit.
/// </summary>
public class CustomAuthenticationStateProvider : AuthenticationStateProvider, IHostEnvironmentAuthenticationStateProvider
{
    private static readonly Task<AuthenticationState> Anonymous =
        Task.FromResult(new AuthenticationState(new ClaimsPrincipal(new ClaimsIdentity())));

    private readonly IHttpContextAccessor _http;
    private Task<AuthenticationState>? _authenticationStateTask;

    public CustomAuthenticationStateProvider(IHttpContextAccessor http)
    {
        _http = http;
    }

    public override Task<AuthenticationState> GetAuthenticationStateAsync()
    {
        if (_authenticationStateTask != null)
            return _authenticationStateTask;

        var user = _http.HttpContext?.User;
        if (user?.Identity?.IsAuthenticated == true)
            return Task.FromResult(new AuthenticationState(user));

        return Anonymous;
    }

    public void SetAuthenticationState(Task<AuthenticationState> authenticationStateTask)
    {
        _authenticationStateTask = authenticationStateTask ?? Anonymous;
        NotifyAuthenticationStateChanged(_authenticationStateTask);
    }

    public Task<AuthenticationState> GetAuth() => GetAuthenticationStateAsync();
}
