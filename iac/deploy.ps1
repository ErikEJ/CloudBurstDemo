$rg = "clouburst-demo1-rg"

New-AzResourceGroupDeployment -ResourceGroupName $rg -TemplateFile main.bicep
