using Microsoft.Data.SqlClient;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddSqlDataSource(builder.Configuration.GetConnectionString("Database"));

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.MapGet("/persons", async (SqlDataSource dataSource) =>
{
    await using var command = dataSource.CreateCommand(@"
SELECT CAST((
SELECT 
    p.[Title]
    ,p.[FirstName]
    ,p.[MiddleName]
    ,p.[LastName]
    ,p.[Suffix]
    ,e.[JobTitle]
    ,[Territory.Name] = st.[Name]
    ,[Territory.Group] = st.[Group]
    ,s.[SalesQuota] AS [Sales.Quota]
    ,s.[SalesYTD] AS [Sales.YTD]
    ,s.[SalesLastYear] AS [Sales.LastYear]
FROM [Sales].[SalesPerson] s
    INNER JOIN [HumanResources].[Employee] e 
    ON e.[BusinessEntityID] = s.[BusinessEntityID]
	INNER JOIN [Person].[Person] p
	ON p.[BusinessEntityID] = s.[BusinessEntityID]
    LEFT OUTER JOIN [Sales].[SalesTerritory] st 
    ON st.[TerritoryID] = s.[TerritoryID]
FOR JSON PATH, ROOT('SalesPersons')
) 
AS NVARCHAR(MAX)) AS JsonResult
");
    var jsonString = (string?)await command.ExecuteScalarAsync();
    if (jsonString == null)
    {
        return JsonDocument.Parse("[]").RootElement;
    }

    return JsonDocument.Parse(jsonString).RootElement;
})
.WithName("GetPersons");

app.Run();
