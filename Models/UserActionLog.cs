using System.ComponentModel.DataAnnotations;

namespace ABFreight.Models
{
    public class UserActionLog
    {
        [Key]
        public Guid Id { get; set; }
        public Guid? UserId { get; set; }
        public string? Action { get; set; }
        public string? Detail { get; set; }
        public DateTime? ActionTime { get; set; }

    }
}
