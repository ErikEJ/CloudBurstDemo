PREP:

Log in to Azure from PS Core prompt and set subscription 

az login

az account set --subscription fffde5cb-cccc-aaaa-eee-457c3292608e

Create “demo” resource group in Sweden


Open portal on resource group

Open VS with solution 

Open PowerPoint


DEMO:

Show empty demo resource group in Portal

Start .\deploy.ps1

Walk through bicep template

Break down connection string!

Show app and run locally with Swagger

Explain simplicity

Show deployed resources, in particular managed identity and identity of web app!

Walk through publish

Run .\Publish.ps1

Navigate to: https://msi-erikej-demo-app.azurewebsites.net/persons and troubleshoot it!

Show configure.ps1 and explain it

Run .\configure.ps1

Run the web app.

Show KUDO Environment to explain login to MSI endpoint

Open query editor in portal, and show sys.database_principals
