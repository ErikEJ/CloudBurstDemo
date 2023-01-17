@description('The admin user object id for the SQL Server')
@secure()
param sqlAdministratorSid string

@description('The AAD login name of the SQL admin user')
param sqlAdministratorLogin string = 'eej@delegate.dk'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Environment name for all resources.')
param environment string

@description('Public IP address')
param publicip string

// https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
var hostingPlanName = 'msi-erikej-${environment}-plan'
var websiteName = 'msi-erikej-${environment}-app'
var sqlserverName = 'msi-erikej-${environment}-sql'
var managedIdentityName = 'msi-erikej-${environment}-id'
var databaseName = 'AdventureworksLT'

// Azure SQL resources
resource sqlServer 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: sqlserverName
  location: location 
  properties: {  
    administrators: {
       principalType: 'User'
       administratorType: 'ActiveDirectory'
       azureADOnlyAuthentication: true
       login: sqlAdministratorLogin
       sid: sqlAdministratorSid
       tenantId: tenant().tenantId
    }    
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  sku: {
    name: 'Basic'
  }
  properties:{
    sampleName: 'AdventureWorksLT'
  }
}

resource allowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2021-02-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource myIp 'Microsoft.Sql/servers/firewallRules@2021-02-01-preview' = {
  parent: sqlServer
  name: 'AllowMyIP'
  properties: {
    endIpAddress: publicip
    startIpAddress: publicip
  }
}

// Managed identity
resource msi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}

// Monitoring
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'AppInsights${websiteName}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

// Web App resources
resource hostingPlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'F1'
  }
}

resource website 'Microsoft.Web/sites@2020-12-01' = { 
  name: websiteName
  location: location
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${msi.id}': {}
    }
  }
  properties: { 
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
          {
             name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
             value: appInsights.properties.ConnectionString
          }
      ]
    }
  }
}

resource connectionStrings 'Microsoft.Web/sites/config@2020-12-01' = {
  parent: website
  name: 'connectionstrings'
  properties: {
    DefaultConnection: {
      value: 'Data Source=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};Connection Timeout=60;Authentication=Active Directory Managed Identity;Encrypt=true;User Id=${msi.properties.clientId}'
      type: 'SQLAzure'
    }
  }
}
