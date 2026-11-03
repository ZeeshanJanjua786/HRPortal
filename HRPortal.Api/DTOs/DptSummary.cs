using System.ComponentModel;

namespace HRPortal.Api.DTOs
{
    public class DptSummary
    {
       // 1.	Each row contains departmentId, departmentName, activeEmployees, averageSalary and pendingLeaveRequests.
       public int DepartmentId { get; set; }
        public string DepartmentName { get; set; } = null!;
        public int ActiveEmployees { get; set; }
        public decimal AverageSalary { get; set; }
        public int PendingLeaveRequests { get; set; }
    }
}
