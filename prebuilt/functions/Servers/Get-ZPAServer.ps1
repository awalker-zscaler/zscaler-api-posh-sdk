Function Get-ZPAServer {
    <#
    .SYNOPSIS
        Gets a specific Server for your Tenant.

    .DESCRIPTION
        A function that returns a configured server for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .PARAMETER serverid
        The id of the server you wish to edit.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] Server Details

    .EXAMPLE
        $servers = Get-ZPAServers -token $token -customerid $customerid -zscalercloud config.zpagov.net -serverid $serverid

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud, # The ZScaler Cloud of your tenant
        [Parameter(Mandatory, Position=3)][string]$serverid # The id of the server you want to edit
    )
    $apiurl = "https://$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/server"
    return Invoke-RestMethod -URI "$($apiurl)/$serverid" -Method Get -ContentType "application/json" -Headers @{ Authorization = "Bearer $token"}
}
