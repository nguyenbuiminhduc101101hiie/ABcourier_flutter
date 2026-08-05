using System.ComponentModel.DataAnnotations;

namespace ABFreight.Models
{
    public class TrangThai
    {
        [Key]
        public Guid Id { get; set; }
        public string Tieude { get; set; }
        public string Noidung { get; set; }

        public string Mamau { get; set; }
    }
}
