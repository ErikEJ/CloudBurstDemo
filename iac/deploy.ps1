$environment = "demo"


$ip = Invoke-RestMethod ipinfo.io/ip

New-AzResourceGroupDeployment -ResourceGroupName "cloudburst-$($environment)-rg" -TemplateFile main.bicep -TemplateParameterFile parameters.json -environment $environment -publicip $ip
