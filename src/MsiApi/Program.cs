using Microsoft.Data.SqlClient;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

// added two packages:
 //< PackageReference Include = "ErikEJ.SqlClient.Extensions" Version = "0.1.2-alpha" />
 //< PackageReference Include = "Microsoft.ApplicationInsights.AspNetCore" Version = "2.21.0" />
builder.Services.AddApplicationInsightsTelemetry();

builder.Services.AddSqlDataSource(builder.Configuration.GetConnectionString("DefaultConnection"));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

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
SELECT CAST((SELECT c.[Title] ,c.[FirstName] ,c.[MiddleName] ,c.[LastName] ,c.[Suffix] 
  ,a.AddressLine1 AS [Address.Line1] ,a.AddressLine2 AS [Address.Line2]	,a.City AS [Address.City] ,a.PostalCode AS [Address.Postalcode]
FROM [SalesLT].[Address] a
    INNER JOIN [SalesLT].[CustomerAddress] ca ON ca.AddressID = a.AddressID
	INNER JOIN [SalesLT].[Customer] c ON c.CustomerID = ca.CustomerID 
FOR JSON PATH, ROOT('Customers')) 
AS NVARCHAR(MAX)) AS JsonResult");
    var jsonString = (string?)await command.ExecuteScalarAsync();
    if (jsonString == null)
    {
        return JsonDocument.Parse("[]").RootElement;
    }

    return JsonDocument.Parse(jsonString).RootElement;
})
.WithName("GetPersons");

app.Run();
