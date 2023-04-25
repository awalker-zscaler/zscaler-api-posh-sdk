Function Get-ZPAAuthDomains{
    <#
    .SYNOPSIS
        Gets all Auth Domains for your Tenant.

    .DESCRIPTION
        A function that returns a list of all authentication domains for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of Auth Domains

    .EXAMPLE
        $authdomains = Get-ZPAAuthDomains -token $token -customerid $customerid -zscalercloud config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "https://$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/authDomains"
    return (Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).authdomains
}
