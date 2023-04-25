Function Remove-ZPAServer {
    <#
    .SYNOPSIS
        Add a new server in your Tenant

    .DESCRIPTION
        A function that adds a server to your ZScaler ZPA Tenant.

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .PARAMETER serverid
        The id of the server you wish to delete.

    .OUTPUTS
        null

    .EXAMPLE
        Remove-ZPAServer -token $token -customerid "72031983339558032" -zscalercloud config.zpagov.net -serverid "72051983339880338"

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)][string]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)][string]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud, # The ZScaler Cloud of your tenant
        [Parameter(Mandatory, Position=3)][string]$serverid # The id of the server you want to edit
    )
    return Invoke-RestMethod -URI "https://$($apiurl)/$serverid" -Method DELETE -ContentType "application/json" -Headers @{ Authorization = "Bearer $token"}
}
