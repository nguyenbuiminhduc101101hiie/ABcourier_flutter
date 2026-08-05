using System.ComponentModel.DataAnnotations;

namespace ABFreight.Models
{
    public class MoveCustomer
    {
        [Key]
        public Guid ID { get; set; }
        public string? CustomerCode { get; set; }
        public string? SaleName { get; set; }
        public DateTime? MoveDate { get; set; }
        public Guid? CustomerID { get; set; }
    }
}
