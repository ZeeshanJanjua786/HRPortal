using System;
using System.Collections.Generic;

namespace HRPortal.Api.Models;

public partial class PublicHoliday
{
    public int HolidayId { get; set; }

    public DateOnly HolidayDate { get; set; }

    public string Name { get; set; } = null!;
}
