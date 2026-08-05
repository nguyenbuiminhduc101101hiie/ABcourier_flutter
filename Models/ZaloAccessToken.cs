using System.ComponentModel.DataAnnotations;

namespace ABFreight.Models
{
    public class ZaloAccessToken
    {
        [Key]
        public string? Accesstoken { get; set; }
        public string? Refreshtoken { get; set; }
    }
}
