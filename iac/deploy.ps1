$environment = "demo"

$ip = Invoke-RestMethod ipinfo.io/ip

New-AzResourceGroupDeployment -ResourceGroupName "msi-erikej-$($environment)-rg" -TemplateFile main.bicep -TemplateParameterFile parameters.json -environment $environment -publicip $ip
