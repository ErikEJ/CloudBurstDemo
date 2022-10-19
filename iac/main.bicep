@description('The admin user object id for the SQL Server')
param sqlAdministratorSid string = '4aa40976-d7c6-47fa-b4ba-cf0621f5de0c'

@description('The login name of the SQL admin user')
param sqlAdministratorLogin string = 'eej@delegate.dk'

@description('Location for all resources.')
param location string = resourceGroup().location

var hostingPlanName = 'hostingplan${uniqueString(resourceGroup().id)}'
var websiteName = 'cloudburstdemoeej'
var sqlserverName = 'sqlServer${uniqueString(resourceGroup().id)}'
var managedIdentityName = 'msi${uniqueString(resourceGroup().id)}'
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
    version: '12.0' 
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

// Web App resources
resource hostingPlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'F1'
  }
}

resource msi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
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
  tags: {
    'hidden-related:${hostingPlan.id}': 'empty'
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
      value: 'Data Source=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};'
      type: 'SQLAzure'
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'AppInsights${websiteName}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}
