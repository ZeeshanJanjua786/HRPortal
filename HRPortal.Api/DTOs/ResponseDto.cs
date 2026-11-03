namespace HRPortal.Api.DTOs
{
    public class ResponseDto
    {
        public string FirstName { get; set; } = null!;

        public string LastName { get; set; } = null!;

        public string Email { get; set; } = null!;

        public string Cnic { get; set; } = null!;
        public string Gender { get; set; } = null!;

        public DateOnly DateOfBirth { get; set; }


        public decimal Salary { get; set; }
        public int DepartmentId { get; set; }
        public int DesignationId { get; set; }
    }
}
