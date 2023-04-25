Function Get-ZPAServers {
    <#
    .SYNOPSIS
        Gets all configured Servers for your Tenant.

    .DESCRIPTION
        A function that returns a list of all configured servers for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of Servers

    .EXAMPLE
        $servers = Get-ZPAServers -token $token -customerid $customerid -zscalercloud config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "https://$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/server"
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
