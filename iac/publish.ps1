$environment = "demo"

dotnet publish ..\src\MsiApi\MsiApi.csproj --output .\publish

Compress-Archive .\publish\* .\app.zip -Force

$app = Get-AzWebApp -ResourceGroupName "msi-erikej-$($environment)-rg" -Name "msi-erikej-$($environment)-app"

Write-Host "Publishing app"

Publish-AzWebApp -WebApp $app -ArchivePath .\app.zip -Timeout 300000 -Force
