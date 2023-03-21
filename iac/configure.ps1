$environment = "demo"

$rg = "msi-erikej-$($environment)-rg"
$miname = "msi-erikej-$($environment)-id"
$sqlServer = "msi-erikej-$($environment)-sql"
$sqlDatabase = "AdventureworksLT"

function ConvertTo-Sid {
    param ([string]$appId)
    [guid]$guid = [System.Guid]::Parse($appId)
    foreach ($byte in $guid.ToByteArray()) {
        $byteGuid += [System.String]::Format("{0:X2}", $byte)
    }
    return "0x" + $byteGuid
}

# Get id, name and SQL accessToken of current identity
$context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
$sqlToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://database.windows.net").AccessToken

Write-Host "Getting token"

Write-Host $sqlToken

# Get managed identity client (application) id
# I needed this on Azure DevOps build agent: Install-Module -Name Az.ManagedServiceIdentity -Scope CurrentUser -Force
$mi = Get-AzUserAssignedIdentity -ResourceGroupName $rg -Name $miname
$appId = $mi.ClientId

Write-Host $appId

# Give User Assigned Managed Identity SQL database access
# You can use this syntax if AAD lookups are allowed
# CREATE USER [$miname] FROM EXTERNAL PROVIDER

$sid = ConvertTo-Sid -appId $appId

$Query = "IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name ='$miname')
            BEGIN
                CREATE USER [$miname] WITH DEFAULT_SCHEMA=[dbo], SID = $sid, TYPE = E;
            END
            IF IS_ROLEMEMBER('db_datareader','$miname') = 0
            BEGIN
                ALTER ROLE db_datareader ADD MEMBER [$miname]
            END
            IF IS_ROLEMEMBER('db_datawriter','$miname') = 0
            BEGIN
                ALTER ROLE db_datawriter ADD MEMBER [$miname]
            END;"

$sqlInstance = $sqlServer + ".database.windows.net"

# I needed to: Install-Module -Name SqlServer locally using PS Core

Write-Host "Creating DB user"

Invoke-Sqlcmd -ServerInstance $sqlInstance -Database $sqlDatabase -AccessToken $sqlToken -Query $Query
