using System;
using System.Collections.Generic;

namespace HRPortal.Api.Models;

public partial class Employee
{
    public int EmployeeId { get; set; }

    public string? EmployeeCode { get; set; }

    public string FirstName { get; set; } = null!;

    public string LastName { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string Cnic { get; set; } = null!;

    public string? Phone { get; set; }

    public string Gender { get; set; } = null!;

    public DateOnly DateOfBirth { get; set; }

    public DateOnly HireDate { get; set; }

    public decimal Salary { get; set; }

    public int DepartmentId { get; set; }

    public int DesignationId { get; set; }

    public int? ManagerId { get; set; }

    public bool IsActive { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual Department Department { get; set; } = null!;

    public virtual Designation Designation { get; set; } = null!;

    public virtual ICollection<Employee> InverseManager { get; set; } = new List<Employee>();

    public virtual ICollection<LeaveRequest> LeaveRequests { get; set; } = new List<LeaveRequest>();

    public virtual Employee? Manager { get; set; }
}
