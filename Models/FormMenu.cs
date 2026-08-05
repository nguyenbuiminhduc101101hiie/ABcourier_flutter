using System.ComponentModel.DataAnnotations;

namespace ABFreight.Models
{
    public class FormMenu
    {
        [Key] public Guid MenuID { get; set; }
        public string? MenuName { get; set; }
        public string? Title { get; set; }
    }
}
