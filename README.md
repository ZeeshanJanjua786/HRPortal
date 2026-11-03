# HRPortal

1. Run HRPortalDb.sql in SQL Server Management Studio.
2. In HRPortal.Api/appsettings.json, replace YOUR_SERVER_NAME with your SQL Server name
   (examples: localhost, .\SQLEXPRESS, (localdb)\MSSQLLocalDB).
3. From the HRPortal.Api folder, scaffold the database using the EF Core CLI
   (the "HRPortalDb" connection string, Models output folder, and DbContext name
   HrPortalDbContext) to generate your DbContext and model classes.
4. Run: dotnet run --launch-profile https and open /swagger.
