using AutoMapper;
using AutoMapper.Features;
using Azure;
using Azure.Core;
using FluentValidation;
using HRPortal.Api.DTOs;
using HRPortal.Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using Microsoft.Identity.Client;
using Microsoft.Win32;
using System.ComponentModel;
using System.Data;
using System.Globalization;
using System.Net.NetworkInformation;
using System.Reflection;
using System.Reflection.Metadata;
using System.Security.Cryptography;
using static Microsoft.EntityFrameworkCore.DbLoggerCategory;
using static System.Net.Mime.MediaTypeNames;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace HRPortal.Api.Controller
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        public readonly HRPortalDbContext _context;
        public readonly IMapper _mapper;
        public readonly IValidator<EmployeeDTO> _validator;
        public UserController(HRPortalDbContext context, IMapper mapper, IValidator<EmployeeDTO> validator)
        {
             _context = context;
             _mapper = mapper;
             _validator = validator;
        }


        [HttpPost]
        public async Task<IActionResult> CreateEmployee(EmployeeDTO dto)
        {
          
            var validate = _validator.Validate(dto);
            if (!validate.IsValid)
            {
                return BadRequest(validate.Errors);
            }

            var emp = _mapper.Map<Employee>(dto);
            _context.Employees.Add(emp);
            await _context.SaveChangesAsync();  

            return Ok(emp);
            
        }

     
      

        //        Task 3 — Employee profile


        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetEmployeeProfile(int id)
        {
            var employee = await _context.Employees
                .Include(e => e.Department)
                .Include(e => e.Designation)
                .Include(e => e.Manager)
                .FirstOrDefaultAsync(e => e.EmployeeId == id);
            if (employee == null)
            {
                return NotFound($"Employee {id} was not found.");
            }
            var profile = new
            {
                employee.EmployeeId,
                employee.EmployeeCode,
                FullName = employee.FirstName + " " + employee.LastName,
                employee.Email,
                Department = employee.Department?.Name,
                Designation = employee.Designation?.Title,
              ManagerName = employee.Manager?.FirstName + " " + employee.Manager?.LastName,
               //YearsOfService = employee.HireDate - employee.,
                IsActive = employee.IsActive
            };
            return Ok(profile);
        }




//        Task 4 — Search employees with paging


        [HttpGet("GetEmployeesPaged")]
        public async Task<IActionResult> GetEmployeesPaged(int? departmentId, bool? isActive, string? search, int page = 1, int pageSize = 5)
        {
            if (page < 1)
            {
                return BadRequest("Page must be 1 or more.");
            }
            if (pageSize < 1 || pageSize > 20)
            {
                return BadRequest("Page size must be between 1 and 20.");
            }
            var query = _context.Employees.AsQueryable();
            if (departmentId.HasValue)
            {
                query = query.Where(e => e.DepartmentId == departmentId.Value);
            }
            if (isActive.HasValue)
            {
                query = query.Where(e => e.IsActive == isActive.Value);
            }
            if (!string.IsNullOrEmpty(search))
            {
                search = search.ToLower();
                query = query.Where(e => e.FirstName.ToLower().Contains(search) ||
                                         e.LastName.ToLower().Contains(search) ||
                                         e.Email.ToLower().Contains(search) ||
                                         e.EmployeeCode.ToLower().Contains(search));
            }
            var totalCount = await query.CountAsync();
            var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);
            var items = await query
                .OrderBy(e => e.EmployeeId)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(e => new
                {
                    e.EmployeeId,
                    e.EmployeeCode,
                    FullName = e.FirstName + " " + e.LastName,
                    Department = e.Department.Name,
                    Designation = e.Designation.Title
                })
                .ToListAsync();
            var result = new
            {
                page,
                pageSize,
                totalCount,
                totalPages,
                items
            };
            return Ok(result);
        }



        //        Task 5 — Department summary report


        [HttpGet("department-summary")]
        public async Task<IActionResult> GetDepartmentSummary(bool onlyActive = false)
        {
            var query = _context.VwDepartmentSummaries.AsQueryable();
            if (onlyActive)
            {
                query = query.Where(d => d.ActiveEmployees > 0);
            }
            var result = await query
                .OrderByDescending(d => d.ActiveEmployees)
                .ThenBy(d => d.DepartmentName)
                .Select(d => new DptSummary
                {
                    DepartmentId = d.DepartmentId,
                    DepartmentName = d.DepartmentName,
                    ActiveEmployees = d.ActiveEmployees ?? 0,
                    AverageSalary = d.AverageSalary ?? 0,
                    PendingLeaveRequests = d.PendingLeaveRequests ?? 0
                })
                .ToListAsync();
            return Ok(result);
        }



        //        //sTask 6 — Apply for leave

      


        [HttpGet("leave-requests")]
        public async Task<IActionResult> GetLeaveRequests(int employeeId, int leaveTypeId, DateTime startDate, DateTime endDate, string reason)
        {
            if (reason.Length < 5 || reason.Length > 250)
            {
                return BadRequest("Reason must be between 5 and 250 characters.");
            }
            if (endDate < startDate)
            {
                return BadRequest("End date must be on or after start date.");
            }
            var result = await _context.LeaveRequests
                .FromSqlInterpolated($"EXEC sp_ApplyLeave @EmployeeId={employeeId}, @LeaveTypeId={leaveTypeId}, @StartDate={startDate}, @EndDate={endDate}, @Reason={reason}")
                .ToListAsync();
            if (result.Count == 0)
            {
                return NotFound($"Employee {employeeId} is missing or inactive.");
            }
            var leaveRequest = result.First();
            if (leaveRequest.Status == "Overlapping")
            {
              
                return Conflict("Overlapping leave request exists.");
            }
            else if (leaveRequest.Status == "QuotaExceeded")
            {
                return UnprocessableEntity("Leave quota exceeded.");
            }
           

            return CreatedAtAction(nameof(GetLeaveRequests), new { id = leaveRequest.LeaveRequestId }, leaveRequest);
        }   







    }
}
