Function Get-ZPAAppSegment{
    <#
    .SYNOPSIS
        Gets a specific App Segment for your Tenant.

    .DESCRIPTION
        A function that returns a specific application segment for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .PARAMETER applicationid
        The id of the app server you wish to edit.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] App Segment Details

    .EXAMPLE
        $appsegment = Get-ZPAAppSegment -token $token -customerid $customerid -zscalercloud config.zpagov.net -applicationid $applicationid

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud, # The ZScaler Cloud of your tenant
        [Parameter(Mandatory, Position=3)][string]$applicationid # The id of the appsegment you want to edit
    )
    $apiurl = "https://$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/server"
    return Invoke-RestMethod -URI "$($apiurl)/$applicationid" -Method Get -ContentType "application/json" -Headers @{ Authorization = "Bearer $token"}
}
