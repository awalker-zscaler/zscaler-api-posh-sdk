Function Get-ZPAAppConnectorGroups{
    <#
    .SYNOPSIS
        Gets all configured App Connector Groups for your Tenant.

    .DESCRIPTION
        A function that returns a list of all configured application connector groups for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of App Connector Groups

    .EXAMPLE
        $appconnectorgroups = Get-ZPAAppConnectorGroups -token $token -customerid $customerid -zscalercloud config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "https://$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/appConnectorGroup"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($apiurl)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
