$rg = "clouburst-demo1-rg"
$appName = "cloudburst-erikej-demo-app"

dotnet publish ..\src\CloudBurstApi\CloudBurstApi.csproj --output .\publish

Compress-Archive .\publish\* .\app.zip -Force

$app = Get-AzWebApp -ResourceGroupName $rg -Name $appName

Publish-AzWebApp -WebApp $app -ArchivePath .\app.zip -Timeout 300000 -Force
