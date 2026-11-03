using FluentValidation;
using HRPortal.Api.DTOs;
using HRPortal.Api.mapper;
using HRPortal.Api.Models;
using HRPortal.Api.Validation;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

var builder = WebApplication.CreateBuilder(args);

// ---------------------------------------------------------------
// Framework setup (already done for you; no changes needed)
// ---------------------------------------------------------------

// Controllers, with automatic 400 responses for invalid models ([ApiController]).
builder.Services.AddControllers();

// Consistent JSON error responses (RFC 7807 ProblemDetails) for unhandled errors.
builder.Services.AddProblemDetails();

// Swagger UI at /swagger.
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new() { Title = "HR Portal API", Version = "v1" });
});

// FluentValidation: every validator class you write in this project
// (classes that inherit AbstractValidator<T>) is registered automatically.
builder.Services.AddValidatorsFromAssemblyContaining<UserValidation>();

//builder.Services.AddScoped<IValidator<EmployeeDTO>, UserValidation>();

builder.Services.AddAutoMapper(cfg => cfg.AddProfile(typeof(empMapper)));

//VAlidation

// ---------------------------------------------------------------
// Database
// Scaffold the database first, then uncomment the lines below.
// The connection string lives in appsettings.json under "HRPortalDb".
// ---------------------------------------------------------------

builder.Services.AddDbContext<HRPortalDbContext>(options =>
     options.UseSqlServer(builder.Configuration.GetConnectionString("HRPortalDb")));

// ---------------------------------------------------------------
// YOUR SERVICES
// Register your own interfaces and classes here
// (for example the working-days calculator in Task 2).
// Choose the lifetime yourself and add a one-line comment explaining why.
// ---------------------------------------------------------------



// ---------------------------------------------------------------
// HTTP pipeline (already done for you; no changes needed)
// ---------------------------------------------------------------
var app = builder.Build();

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "HR Portal API v1");
    });
}

app.UseHttpsRedirection();

app.MapControllers();


app.Run();
