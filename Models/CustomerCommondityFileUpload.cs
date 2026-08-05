using System.ComponentModel.DataAnnotations;

namespace ABFreight.Models
{
    public class CustomerCommondityFileUpload
    {
        [Key]
        public Guid FileID { get; set; }
        public Guid? CustomerCommondityID { get; set; }
        public string? Link { get; set; }
        public string? FileName { get; set; }
        public string? UserUpdate { get; set; }
        public DateTime? DateUpdate { get; set; }
    }
}
