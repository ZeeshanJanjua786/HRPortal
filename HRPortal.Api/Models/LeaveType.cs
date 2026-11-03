using System;
using System.Collections.Generic;

namespace HRPortal.Api.Models;

public partial class LeaveType
{
    public int LeaveTypeId { get; set; }

    public string Name { get; set; } = null!;

    public byte AnnualQuota { get; set; }

    public virtual ICollection<LeaveRequest> LeaveRequests { get; set; } = new List<LeaveRequest>();
}
