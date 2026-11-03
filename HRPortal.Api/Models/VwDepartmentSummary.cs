using System;
using System.Collections.Generic;

namespace HRPortal.Api.Models;

public partial class VwDepartmentSummary
{
    public int DepartmentId { get; set; }

    public string DepartmentName { get; set; } = null!;

    public bool DepartmentIsActive { get; set; }

    public int? ActiveEmployees { get; set; }

    public decimal? AverageSalary { get; set; }

    public int? PendingLeaveRequests { get; set; }
}
