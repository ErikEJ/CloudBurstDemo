$environment = "demo"

dotnet publish ..\src\CloudBurstApi\CloudBurstApi.csproj --output .\publish

Compress-Archive .\publish\* .\app.zip -Force

$app = Get-AzWebApp -ResourceGroupName "cloudburst-$($environment)-rg" -Name "cloudburst-erikej-$($environment)-app"

Publish-AzWebApp -WebApp $app -ArchivePath .\app.zip -Timeout 300000 -Force
