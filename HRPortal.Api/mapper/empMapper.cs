using AutoMapper;
using HRPortal.Api.DTOs;
using HRPortal.Api.Models;

namespace HRPortal.Api.mapper
{
    public class empMapper : Profile
    {
        public empMapper()
        {
            CreateMap<EmployeeDTO, Employee>().ReverseMap();
            CreateMap<ResponseDto, Employee>().ReverseMap();
            CreateMap<DptSummary, Employee>().ReverseMap();
            
        }
    }
}
