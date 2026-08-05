using ABFreight.Models;
using ABFreight.Response;

namespace ABFreight.Interface
{
    public interface IUserService
    {
        Task<LoginResponse> SignInAsync(string userCredential);
    }
}
