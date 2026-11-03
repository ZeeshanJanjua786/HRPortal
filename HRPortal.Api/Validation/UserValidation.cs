using FluentValidation;
using HRPortal.Api.DTOs;
using HRPortal.Api.Models;
using HRPortal.Api.Validation;

namespace HRPortal.Api.Validation
{
    public class UserValidation : AbstractValidator<EmployeeDTO>
    {
        public readonly HRPortalDbContext context;
         //context = Validation._context;
        //public readonly HRPortalDbContext _context;
        public UserValidation(HRPortalDbContext _context)
        {
            context = _context;


            RuleFor(e => e.Email)
                .Must(x => x.EndsWith("@volmatica.com"))
                .WithMessage("Email must end with @volmatica.com")
                .EmailAddress().NotEmpty();
            
            RuleFor(c => c.Cnic)
                .Must((cnic) =>
                {
                    return !_context.Employees.Any(e => e.Cnic == cnic);
                })
                .WithMessage("Email already Exist in the databse")
                .Matches(@"\d{5}-\d{7}-\d$");




        }
    }
}
