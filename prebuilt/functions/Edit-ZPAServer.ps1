Function Edit-ZPAServer {
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
        The id of the server you wish to edit.

    .PARAMETER address
        The IP address of the server you are editing.

    .PARAMETER name
        The hostname of the server you are editing.

    .PARAMETER description
        A friendly description of the server you are editing.

    .PARAMETER configspace
        Whether the configuration is created as part of a SIEM or application resource, if so, specify the name of the space.  Defaults to "DEFAULT"

    .PARAMETER enabled
        Sets whether the server you are editing should be enabled. Default is disabled.

    .OUTPUTS
        null

    .EXAMPLE
        Edit-ZPAServer -token $token -customerid "72031983339558032" -zscalercloud config.zpagov.net -serverid "72051983339880338" -address "10.0.115.28" -name "SomeTestServer3" -description "Just another test server" -enabled $false -configspace "DEFAULT"

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)][string]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)][string]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud, # The ZScaler Cloud of your tenant
        [Parameter(Mandatory, Position=3)][string]$serverid, # The id of the server you want to edit
        [Parameter(Mandatory=$FALSE)][string]$address, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory=$FALSE)][string]$name, # The hostname of the server you are editing.
        [Parameter(Mandatory=$FALSE)][string]$description, # A friendly description of the server you are editing.
        [Parameter(Mandatory=$FALSE)][string]$configspace, # Whether the configuration is created as part of a SIEM or application resource, if so, specify the name of the space.
        [Parameter(Mandatory=$FALSE)][bool]$enabled # Sets whether the server you are editing should be enabled. 
    )
    # Get Current Data for this server
    $original = Invoke-RestMethod -URI "https://$($apiurl)/$serverid" -Method Get -ContentType "application/json" -Headers @{ Authorization = "Bearer $token"}
    $data = @{}
    # Check if enabled has changed, if so, update the post values, if not, use the orginal value.
    IF($null -ne $enabled -and $enabled -ne $original.enabled){IF($enabled){$data += @{enabled = "true"}}ELSEIF($null -ne $enabled){$data += @{enabled = "false"}}}ELSE{$data += @{enabled = $original.enabled}}
    # Check if address has changed, if so, update the post values, if not, use the orginal value.
    IF($null -ne $address -and $address -ne $original.address){$data += @{address = $address}}ELSE{$data += @{address = $original.address}}
    # Check if name has changed, if so, update the post values, if not, use the orginal value.
    IF($null -ne $name -and $name -ne $original.name){$data += @{name = $name}}ELSE{$data += @{name = $original.name}}
    # Check if configSpace has changed, if so, update the post values, if not, use the orginal value.
    IF($null -ne $configspace -and $configspace -ne $original.configspace){$data += @{configSpace = $configspace}}ELSE{$data += @{configSpace = $original.configspace}}
    # Check if description has changed, if so, update the post values, if not, use the orginal value.
    IF($null -ne $description -and $description -ne $original.description){$data += @{description = $description}}ELSE{$data += @{description = $original.description}}
    $post = ($data | ConvertTo-Json)
    $apiurl = "https://$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/server"
    $response = Invoke-RestMethod -URI "$($apiurl)/$serverid" -Method Put -ContentType "application/json" -Headers @{ Authorization = "Bearer $token"} -Body $post
    return $response

}
