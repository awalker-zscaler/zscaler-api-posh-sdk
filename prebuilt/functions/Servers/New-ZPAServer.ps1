Function New-ZPAServer {
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

    .PARAMETER address
        The IP address of the server you are adding.

    .PARAMETER name
        The hostname of the server you are adding.

    .PARAMETER description
        A friendly description of the server you are adding.

    .PARAMETER configspace
        Whether the configuration is created as part of a SIEM or application resource, if so, specify the name of the space.  Defaults to "DEFAULT"

    .PARAMETER enabled
        Sets whether the server you are adding should be enabled. Default is disabled.

    .OUTPUTS
        When successful, the response will contain the information for the server you just created. 

        id           : 72058033198333988
        creationTime : 1680796137
        modifiedBy   : 72058033198333983
        name         : SomeTestServer2
        address      : 10.0.115.26
        enabled      : True
        description  : Just a test server.
        configSpace  : DEFAULT

    .EXAMPLE
        New-ZPAServer -token $token -customerid $customerid -zscalercloud config.zpagov.net -address "10.0.115.26" -name "SomeTestServer2" -description "Just a test server." -enabled

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)][string]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)][string]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud, # The ZScaler Cloud of your tenant
        [Parameter(Mandatory, Position=3)][string]$address, # The IP address of the server you are adding.
        [Parameter(Mandatory, Position=4)][string]$name, # The hostname of the server you are adding.
        [Parameter(Mandatory=$FALSE)][string]$description, # A friendly description of the server you are adding.
        [Parameter(Mandatory=$FALSE)][string]$configspace="DEFAULT", # Whether the configuration is created as part of a SIEM or application resource, if so, specify the name of the space.  Defaults to "DEFAULT"
        [Parameter(Mandatory=$FALSE)][switch]$enabled # Sets whether the server you are adding should be enabled. Default is disabled.
    )
    $data = @{}
    $data += @{
        address = $address
        configSpace = $configspace
        name = $name
    }
    IF($enabled){$data += @{enabled = "true"}}ELSE{$data += @{enabled = "false"}}
    IF($null -ne $description){$data += @{description = $description}}
    $post = ($data | ConvertTo-Json)
    $apiurl = "https://$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/server"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Post -ContentType "application/json" -Headers @{ Authorization = "Bearer $token"} -Body $post
    return $response
}
