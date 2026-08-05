using System.ComponentModel.DataAnnotations;

namespace ABFreight.Models
{
    public class M_ListDept
    {
        [Key]
        public Guid id { get; set; }
        public string? Viewername { get; set; }
        public string? tablename { get; set; }
    }
}
