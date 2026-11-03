/* =========================================================
   HRPortalDb  —  .NET Week 2 Assessment
   Run once in SQL Server Management Studio / Azure Data Studio.
   Creates 6 tables, 1 view, 2 stored procedures and seed data.
   ========================================================= */
USE master;
GO
IF DB_ID('HRPortalDb') IS NOT NULL
BEGIN
    ALTER DATABASE HRPortalDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE HRPortalDb;
END
GO
CREATE DATABASE HRPortalDb;
GO
USE HRPortalDb;
GO

/* ---------- 1. Departments ---------- */
CREATE TABLE dbo.Departments (
    DepartmentId  INT IDENTITY(1,1) NOT NULL,
    Name          NVARCHAR(100)     NOT NULL,
    Location      NVARCHAR(100)     NULL,
    IsActive      BIT               NOT NULL CONSTRAINT DF_Departments_IsActive  DEFAULT (1),
    CreatedAt     DATETIME2(0)      NOT NULL CONSTRAINT DF_Departments_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Departments      PRIMARY KEY (DepartmentId),
    CONSTRAINT UQ_Departments_Name UNIQUE (Name)
);

/* ---------- 2. Designations ---------- */
CREATE TABLE dbo.Designations (
    DesignationId INT IDENTITY(1,1) NOT NULL,
    Title         NVARCHAR(100)     NOT NULL,
    Grade         TINYINT           NOT NULL,
    CONSTRAINT PK_Designations       PRIMARY KEY (DesignationId),
    CONSTRAINT UQ_Designations_Title UNIQUE (Title),
    CONSTRAINT CK_Designations_Grade CHECK (Grade BETWEEN 1 AND 10)
);

/* ---------- 3. Employees ---------- */
CREATE TABLE dbo.Employees (
    EmployeeId    INT IDENTITY(1,1) NOT NULL,
    EmployeeCode  AS ('VOL-' + RIGHT('0000' + CAST(EmployeeId AS VARCHAR(10)), 4)) PERSISTED,
    FirstName     NVARCHAR(50)      NOT NULL,
    LastName      NVARCHAR(50)      NOT NULL,
    Email         NVARCHAR(150)     NOT NULL,
    CNIC          CHAR(15)          NOT NULL,
    Phone         VARCHAR(15)       NULL,
    Gender        CHAR(1)           NOT NULL,
    DateOfBirth   DATE              NOT NULL,
    HireDate      DATE              NOT NULL CONSTRAINT DF_Employees_HireDate  DEFAULT (CAST(GETDATE() AS DATE)),
    Salary        DECIMAL(12,2)     NOT NULL,
    DepartmentId  INT               NOT NULL,
    DesignationId INT               NOT NULL,
    ManagerId     INT               NULL,
    IsActive      BIT               NOT NULL CONSTRAINT DF_Employees_IsActive  DEFAULT (1),
    CreatedAt     DATETIME2(0)      NOT NULL CONSTRAINT DF_Employees_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Employees              PRIMARY KEY (EmployeeId),
    CONSTRAINT UQ_Employees_Email        UNIQUE (Email),
    CONSTRAINT UQ_Employees_CNIC         UNIQUE (CNIC),
    CONSTRAINT CK_Employees_EmailDomain  CHECK (Email LIKE '_%@volmatica.com'),
    CONSTRAINT CK_Employees_CNICFormat   CHECK (CNIC LIKE '[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'),
    CONSTRAINT CK_Employees_Gender       CHECK (Gender IN ('M','F')),
    CONSTRAINT CK_Employees_Salary       CHECK (Salary > 0),
    CONSTRAINT CK_Employees_HireAfterDOB CHECK (HireDate > DateOfBirth),
    CONSTRAINT FK_Employees_Departments  FOREIGN KEY (DepartmentId)  REFERENCES dbo.Departments(DepartmentId),
    CONSTRAINT FK_Employees_Designations FOREIGN KEY (DesignationId) REFERENCES dbo.Designations(DesignationId),
    CONSTRAINT FK_Employees_Manager      FOREIGN KEY (ManagerId)     REFERENCES dbo.Employees(EmployeeId)
);
CREATE INDEX IX_Employees_DepartmentId ON dbo.Employees(DepartmentId);

/* ---------- 4. LeaveTypes ---------- */
CREATE TABLE dbo.LeaveTypes (
    LeaveTypeId  INT IDENTITY(1,1) NOT NULL,
    Name         NVARCHAR(50)      NOT NULL,
    AnnualQuota  TINYINT           NOT NULL,
    CONSTRAINT PK_LeaveTypes       PRIMARY KEY (LeaveTypeId),
    CONSTRAINT UQ_LeaveTypes_Name  UNIQUE (Name),
    CONSTRAINT CK_LeaveTypes_Quota CHECK (AnnualQuota > 0)
);

/* ---------- 5. LeaveRequests ---------- */
CREATE TABLE dbo.LeaveRequests (
    LeaveRequestId INT IDENTITY(1,1) NOT NULL,
    EmployeeId     INT               NOT NULL,
    LeaveTypeId    INT               NOT NULL,
    StartDate      DATE              NOT NULL,
    EndDate        DATE              NOT NULL,
    TotalDays      AS (DATEDIFF(DAY, StartDate, EndDate) + 1) PERSISTED,
    Reason         NVARCHAR(250)     NOT NULL,
    Status         VARCHAR(10)       NOT NULL CONSTRAINT DF_LeaveRequests_Status    DEFAULT ('Pending'),
    AppliedAt      DATETIME2(0)      NOT NULL CONSTRAINT DF_LeaveRequests_AppliedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_LeaveRequests            PRIMARY KEY (LeaveRequestId),
    CONSTRAINT CK_LeaveRequests_Dates      CHECK (EndDate >= StartDate),
    CONSTRAINT CK_LeaveRequests_Status     CHECK (Status IN ('Pending','Approved','Rejected','Cancelled')),
    CONSTRAINT FK_LeaveRequests_Employees  FOREIGN KEY (EmployeeId)  REFERENCES dbo.Employees(EmployeeId),
    CONSTRAINT FK_LeaveRequests_LeaveTypes FOREIGN KEY (LeaveTypeId) REFERENCES dbo.LeaveTypes(LeaveTypeId)
);
CREATE INDEX IX_LeaveRequests_Employee_Dates ON dbo.LeaveRequests(EmployeeId, StartDate, EndDate);

/* ---------- 6. PublicHolidays ---------- */
CREATE TABLE dbo.PublicHolidays (
    HolidayId    INT IDENTITY(1,1) NOT NULL,
    HolidayDate  DATE              NOT NULL,
    Name         NVARCHAR(100)     NOT NULL,
    CONSTRAINT PK_PublicHolidays      PRIMARY KEY (HolidayId),
    CONSTRAINT UQ_PublicHolidays_Date UNIQUE (HolidayDate)
);
GO

/* ---------- Seed data ---------- */
INSERT INTO dbo.Departments (Name, Location, IsActive) VALUES
 (N'Engineering',     N'Islamabad',  1),   -- 1
 (N'Human Resources', N'Rawalpindi', 1),   -- 2
 (N'Finance',         N'Islamabad',  1),   -- 3
 (N'Sales',           N'Lahore',     1),   -- 4
 (N'Legacy Support',  N'Rawalpindi', 0);   -- 5

INSERT INTO dbo.Designations (Title, Grade) VALUES
 (N'Engineering Manager',      8),  -- 1
 (N'HR Manager',               8),  -- 2
 (N'Senior Software Engineer', 6),  -- 3
 (N'Software Engineer',        4),  -- 4
 (N'HR Executive',             4),  -- 5
 (N'Accountant',               5),  -- 6
 (N'Sales Executive',          3);  -- 7

-- Managers first (ManagerId NULL), then their reports
INSERT INTO dbo.Employees
 (FirstName, LastName, Email, CNIC, Phone, Gender, DateOfBirth, HireDate, Salary, DepartmentId, DesignationId, ManagerId, IsActive) VALUES
 (N'Ayesha', N'Khan',  N'ayesha.khan@volmatica.com',  '61101-2345678-2', '0300-1112233', 'F', '1988-05-14', '2019-03-01', 450000, 1, 1, NULL, 1), -- 1
 (N'Bilal',  N'Ahmed', N'bilal.ahmed@volmatica.com',  '37405-3456789-1', '0301-2223344', 'M', '1985-11-02', '2018-07-15', 380000, 2, 2, NULL, 1), -- 2
 (N'Sana',   N'Malik', N'sana.malik@volmatica.com',   '61101-4567890-4', NULL,           'F', '1990-02-20', '2020-01-10', 220000, 3, 6, NULL, 1), -- 3
 (N'Hamza',  N'Raza',  N'hamza.raza@volmatica.com',   '35202-5678901-3', '0321-3334455', 'M', '1992-08-08', '2020-09-01', 320000, 1, 3, 1,    1), -- 4
 (N'Fatima', N'Noor',  N'fatima.noor@volmatica.com',  '61101-6789012-8', '0333-4445566', 'F', '1998-12-30', '2023-02-13', 180000, 1, 4, 1,    1), -- 5
 (N'Usman',  N'Tariq', N'usman.tariq@volmatica.com',  '37405-7890123-5', NULL,           'M', '1999-04-17', '2024-06-03', 175000, 1, 4, 1,    1), -- 6
 (N'Zainab', N'Ali',   N'zainab.ali@volmatica.com',   '37405-8901234-6', '0345-5556677', 'F', '1996-07-09', '2022-11-21', 140000, 2, 5, 2,    1), -- 7
 (N'Ali',    N'Hassan',N'ali.hassan@volmatica.com',   '35202-9012345-7', '0300-6667788', 'M', '1995-01-25', '2021-05-17', 120000, 4, 7, NULL, 1), -- 8
 (N'Hira',   N'Shah',  N'hira.shah@volmatica.com',    '35202-0123456-0', NULL,           'F', '2000-10-11', '2025-01-06', 115000, 4, 7, 8,    1), -- 9
 (N'Kamran', N'Javed', N'kamran.javed@volmatica.com', '61101-1122334-9', '0312-7778899', 'M', '1994-03-03', '2021-03-15', 170000, 1, 4, 1,    0); -- 10 (inactive)

INSERT INTO dbo.LeaveTypes (Name, AnnualQuota) VALUES
 (N'Annual', 14),  -- 1
 (N'Sick',    8),  -- 2
 (N'Casual', 10);  -- 3

INSERT INTO dbo.LeaveRequests (EmployeeId, LeaveTypeId, StartDate, EndDate, Reason, Status) VALUES
 (4, 1, '2026-10-12', '2026-10-14', N'Family event',       'Approved'),  -- 1
 (5, 2, '2026-10-20', '2026-10-21', N'Fever',              'Approved'),  -- 2
 (6, 1, '2026-11-16', '2026-11-20', N'Travelling home',    'Pending'),   -- 3
 (7, 3, '2026-11-10', '2026-11-10', N'Bank work',          'Pending'),   -- 4
 (9, 1, '2026-12-28', '2026-12-31', N'Year-end vacation',  'Pending'),   -- 5
 (5, 3, '2026-09-07', '2026-09-07', N'Personal errand',    'Rejected'),  -- 6
 (4, 1, '2026-12-21', '2026-12-24', N'Winter break',       'Pending');   -- 7

INSERT INTO dbo.PublicHolidays (HolidayDate, Name) VALUES
 ('2026-11-09', N'Iqbal Day'),
 ('2026-12-25', N'Quaid-e-Azam Day'),
 ('2027-02-05', N'Kashmir Solidarity Day'),
 ('2027-03-23', N'Pakistan Day');
GO

/* ---------- View: department summary ---------- */
CREATE VIEW dbo.vw_DepartmentSummary
AS
SELECT
    d.DepartmentId,
    d.Name                                         AS DepartmentName,
    d.IsActive                                     AS DepartmentIsActive,
    COUNT(DISTINCT CASE WHEN e.IsActive = 1 THEN e.EmployeeId END) AS ActiveEmployees,
    CAST(ISNULL(AVG(CASE WHEN e.IsActive = 1 THEN e.Salary END), 0) AS DECIMAL(12,2)) AS AverageSalary,
    (SELECT COUNT(*)
       FROM dbo.LeaveRequests lr
       JOIN dbo.Employees e2 ON e2.EmployeeId = lr.EmployeeId
      WHERE e2.DepartmentId = d.DepartmentId
        AND lr.Status = 'Pending')                 AS PendingLeaveRequests
FROM dbo.Departments d
LEFT JOIN dbo.Employees e ON e.DepartmentId = d.DepartmentId
GROUP BY d.DepartmentId, d.Name, d.IsActive;
GO

/* ---------- Stored procedure: apply for leave ---------- */
CREATE PROCEDURE dbo.sp_ApplyLeave
    @EmployeeId  INT,
    @LeaveTypeId INT,
    @StartDate   DATE,
    @EndDate     DATE,
    @Reason      NVARCHAR(250)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Employees WHERE EmployeeId = @EmployeeId AND IsActive = 1)
        THROW 50001, 'Employee not found or inactive.', 1;

    IF EXISTS (SELECT 1 FROM dbo.LeaveRequests
                WHERE EmployeeId = @EmployeeId
                  AND Status IN ('Pending','Approved')
                  AND StartDate <= @EndDate
                  AND EndDate   >= @StartDate)
        THROW 50002, 'Leave overlaps an existing Pending or Approved request.', 1;

    DECLARE @Quota INT = (SELECT AnnualQuota FROM dbo.LeaveTypes WHERE LeaveTypeId = @LeaveTypeId);
    DECLARE @Used  INT = (SELECT ISNULL(SUM(TotalDays), 0) FROM dbo.LeaveRequests
                           WHERE EmployeeId = @EmployeeId
                             AND LeaveTypeId = @LeaveTypeId
                             AND Status IN ('Pending','Approved')
                             AND YEAR(StartDate) = YEAR(@StartDate));

    IF @Used + DATEDIFF(DAY, @StartDate, @EndDate) + 1 > @Quota
        THROW 50003, 'Yearly quota for this leave type would be exceeded.', 1;

    INSERT INTO dbo.LeaveRequests (EmployeeId, LeaveTypeId, StartDate, EndDate, Reason)
    VALUES (@EmployeeId, @LeaveTypeId, @StartDate, @EndDate, @Reason);

    SELECT * FROM dbo.LeaveRequests WHERE LeaveRequestId = CAST(SCOPE_IDENTITY() AS INT);
END
GO

/* ---------- Stored procedure: search employees with paging ---------- */
-- Every parameter is optional. TotalCount (all matching rows, before paging)
-- is repeated on every row so the API can build the paging response.
CREATE PROCEDURE dbo.sp_GetEmployeesPaged
    @DepartmentId INT           = NULL,
    @IsActive     BIT           = NULL,
    @Search       NVARCHAR(100) = NULL,
    @Page         INT           = 1,
    @PageSize     INT           = 5
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page IS NULL OR @Page < 1
        THROW 50004, 'Page must be 1 or more.', 1;

    IF @PageSize IS NULL OR @PageSize < 1 OR @PageSize > 20
        THROW 50005, 'PageSize must be between 1 and 20.', 1;

    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), N'');

    SELECT
        e.EmployeeId,
        e.EmployeeCode,
        e.FirstName + N' ' + e.LastName AS FullName,
        e.Email,
        d.Name                          AS Department,
        g.Title                         AS Designation,
        e.IsActive,
        COUNT(*) OVER ()                AS TotalCount
    FROM dbo.Employees    e
    JOIN dbo.Departments  d ON d.DepartmentId  = e.DepartmentId
    JOIN dbo.Designations g ON g.DesignationId = e.DesignationId
    WHERE (@DepartmentId IS NULL OR e.DepartmentId = @DepartmentId)
      AND (@IsActive     IS NULL OR e.IsActive     = @IsActive)
      AND (@Search       IS NULL
           OR e.FirstName    LIKE N'%' + @Search + N'%'
           OR e.LastName     LIKE N'%' + @Search + N'%'
           OR e.Email        LIKE N'%' + @Search + N'%'
           OR e.EmployeeCode LIKE N'%' + @Search + N'%')
    ORDER BY e.EmployeeId
    OFFSET (@Page - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY
    OPTION (RECOMPILE);
END
GO

/* ---------- Quick checks (expected results on seed data) ----------
EXEC dbo.sp_GetEmployeesPaged @DepartmentId = 1;              -- 5 rows, TotalCount 5
EXEC dbo.sp_GetEmployeesPaged @DepartmentId = 1, @IsActive = 1; -- 4 rows, TotalCount 4
EXEC dbo.sp_GetEmployeesPaged @Search = N'sha';               -- Ayesha Khan, Hira Shah
EXEC dbo.sp_GetEmployeesPaged @Page = 2, @PageSize = 4;       -- ids 5-8, TotalCount 10
EXEC dbo.sp_GetEmployeesPaged @PageSize = 50;                 -- error 50005
---------------------------------------------------------------------- */


select * from LeaveRequests

select * from Employees