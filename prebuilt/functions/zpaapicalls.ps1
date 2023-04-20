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
        $servers = Get-ZPAServers -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/server"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
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
        $servers = Get-ZPAServers -token $token -customerid $customerid -zscalercloud https://config.zpagov.net -serverid $serverid

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud, # The ZScaler Cloud of your tenant
        [Parameter(Mandatory, Position=3)][string]$serverid # The id of the server you want to edit
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/server"
    return Invoke-RestMethod -URI "$($apiurl)/$serverid" -Method Get -ContentType "application/json" -Headers @{ Authorization = "Bearer $token"}
}
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
        New-ZPAServer -token $token -customerid $customerid -zscalercloud https://config.zpagov.net -address "10.0.115.26" -name "SomeTestServer2" -description "Just a test server." -enabled

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
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/server"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Post -ContentType "application/json" -Headers @{ Authorization = "Bearer $token"} -Body $post
    return $response
}
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
        Edit-ZPAServer -token $token -customerid "72031983339558032" -zscalercloud https://config.zpagov.net -serverid "72051983339880338" -address "10.0.115.28" -name "SomeTestServer3" -description "Just another test server" -enabled $false -configspace "DEFAULT"

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
    $original = Invoke-RestMethod -URI "$($apiurl)/$serverid" -Method Get -ContentType "application/json" -Headers @{ Authorization = "Bearer $token"}
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
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/server"
    $response = Invoke-RestMethod -URI "$($apiurl)/$serverid" -Method Put -ContentType "application/json" -Headers @{ Authorization = "Bearer $token"} -Body $post
    return $response

}
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
        Remove-ZPAServer -token $token -customerid "72031983339558032" -zscalercloud https://config.zpagov.net -serverid "72051983339880338"

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)][string]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)][string]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud, # The ZScaler Cloud of your tenant
        [Parameter(Mandatory, Position=3)][string]$serverid # The id of the server you want to edit
    )
    return Invoke-RestMethod -URI "$($apiurl)/$serverid" -Method DELETE -ContentType "application/json" -Headers @{ Authorization = "Bearer $token"}
}
Function Get-ZPAAppSegments{
    <#
    .SYNOPSIS
        Gets all configured App Segments for your Tenant.

    .DESCRIPTION
        A function that returns a list of all configured application segments for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of App Segments

    .EXAMPLE
        $appsegments = Get-ZPAAppSegments -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/application"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
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
        $appsegment = Get-ZPAAppSegment -token $token -customerid $customerid -zscalercloud https://config.zpagov.net -applicationid $applicationid

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud, # The ZScaler Cloud of your tenant
        [Parameter(Mandatory, Position=3)][string]$applicationid # The id of the appsegment you want to edit
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/server"
    return Invoke-RestMethod -URI "$($apiurl)/$applicationid" -Method Get -ContentType "application/json" -Headers @{ Authorization = "Bearer $token"}
}
Function New-ZPAAppSegment{}
Function Edit-ZPAAppSegment{}
Function Remove-ZPAAppSegment{}
Function Get-ZPASegmentGroups{
    <#
    .SYNOPSIS
        Gets all configured App Segment Groups for your Tenant.

    .DESCRIPTION
        A function that returns a list of all configured application segment groups for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of App Segment Groups

    .EXAMPLE
        $segmentgroups = Get-ZPASegmentGroups -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/segmentGroup"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPASegmentGroup {
    <#
    .SYNOPSIS
        Gets a specific Segment Group for your Tenant.

    .DESCRIPTION
        A function that returns a specific segment group for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .PARAMETER applicationid
        The id of the server group you wish to edit.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] App Segment Details

    .EXAMPLE
        $appsegment = Get-ZPAAppSegment -token $token -customerid $customerid -zscalercloud https://config.zpagov.net -appsegmentid $appsegmentid

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud, # The ZScaler Cloud of your tenant
        [Parameter(Mandatory, Position=3)][string]$appsegmentid # The id of the appsegment you want to edit
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/segmentGroup"
    return Invoke-RestMethod -URI "$($apiurl)/$appsegmentid" -Method Get -ContentType "application/json" -Headers @{ Authorization = "Bearer $token"}
}
Function New-ZPASegmentGroup{}
Function Edit-ZPASegmentGroup{}
Function Remove-ZPASegmentGroup{}
Function Get-ZPAConnectors{
    <#
    .SYNOPSIS
        Gets all configured App Connectors for your Tenant.

    .DESCRIPTION
        A function that returns a list of all configured application connectors for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of App Connectors

    .EXAMPLE
        $appconnectors = Get-ZPAConnectors -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/connector"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAConnector{}
Function Edit-ZPAConnector{}
Function Remove-ZPAConnector{}
Function Remove-ZPAConnectors{}
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
        $appconnectorgroups = Get-ZPAAppConnectorGroups -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/appConnectorGroup"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAAppConnectorGroup{}
Function New-ZPAAppConnectorGroup{}
Function Edit-ZPAAppConnectorGroup{}
Function Remove-ZPAAppConnectorGroup{}
Function Get-ZPACertificates{
    <#
    .SYNOPSIS
        Gets all configured Certificates for your Tenant.

    .DESCRIPTION
        A function that returns a list of all configured certificates for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of Certificates

    .EXAMPLE
        $certificates = Get-ZPACertificates -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/certificate"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPACertificate{}
Function New-ZPACertificate{}
Function Remove-ZPACertificate{}
Function Get-ZPAIssuedCertificates{
    <#
    .SYNOPSIS
        Gets all issued Certificates for your Tenant.

    .DESCRIPTION
        A function that returns a list of all issued certificates for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of Issued Certificates

    .EXAMPLE
        $issuedcertificates = Get-ZPAIssuedCertificates -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/certificate/issued"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
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
        $authdomains = Get-ZPAAuthDomains -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/authDomains"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAVersionProfiles{
    <#
    .SYNOPSIS
        Gets all Version Profiles for your Tenant.

    .DESCRIPTION
        A function that returns a list of all version profiles for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of Version Profiles

    .EXAMPLE
        $versionprofiles = Get-ZPAVersionProfiles -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/visible/versionProfiles"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPACloudConnectorGroups{
    <#
    .SYNOPSIS
        Gets all Cloud Connector Groups for your Tenant.

    .DESCRIPTION
        A function that returns a list of all Cloud Connector Groups for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of Cloud Connector Groups

    .EXAMPLE
        $cloudconnectorgroups = Get-ZPACloudConnectorGroups -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/cloudConnectorGroup"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPACloudConnectorGroup{}
Function Get-ZPAIdentityProviders{}
Function Get-ZPAIdentityProvider{}
Function Get-ZPAInspectionActionTypes{
    <#
    .SYNOPSIS
        Gets all inspection control action types for your Tenant.

    .DESCRIPTION
        A function that returns a list of all inspection control action types for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of inspection control action types

    .EXAMPLE
        $inspectionactiontypes = Get-ZPAInspectionActionTypes -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/inspectionControls/actionTypes"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAInspectionControlTypes{
    <#
    .SYNOPSIS
        Gets all Inspection Control Types for your Tenant.

    .DESCRIPTION
        A function that returns a list of all Inspection Control Types for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of Inspection Control Types

    .EXAMPLE
        $inspectioncontroltypes = Get-ZPAInspectionControlTypes -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/controlTypes"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAInspectionCustomControls{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAInspectionCustomControl{}
Function Get-ZPAInspectionCustomControlName{}
Function New-ZPAInspectionCustomControl{}
Function Edit-ZPAInspectionCustomControl{}
Function Remove-ZPAInspectionCustomControl{}
Function Get-ZPAInspectionHttpMethods{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAInspectionPredefinedControls{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAInspectionPredefinedControl{}
Function Get-ZPAInspectionPredefinedControlVersions{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAInspectionCustomControlTypes{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAInspectionProfiles{
    <#
    .SYNOPSIS
        Gets all inspection profiles for your Tenant.

    .DESCRIPTION
        A function that returns a list of all inspection profiles for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of Inspection Profiles

    .EXAMPLE
        $inspectionprofiles = Get-ZPAInspectionActionTypes -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/inspectionProfile"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAInspectionProfile{}
Function Edit-ZPAInspectionProfile{}
Function Remove-ZPAInspectionProfile{}
Function Edit-ZPAInspectionProfileAssociation{}
Function Edit-ZPAInspectionProfilePatchAssociation{}
Function Get-ZPAMachineGroups{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAMachineGroup{}
Function Edit-ZPAMachineGroup{}
Function Remove-ZPAMachineGroup{}
Function Get-ZPAClientTypes{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAPlatforms{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAPolicySetRule{}
Function Edit-ZPAPolicySetRule{}
Function New-ZPAPolicySetRule{}
Function Remove-ZPAPolicySetRule{}
Function Edit-ZPAPolicySetRuleOrder{}
Function Get-ZPAPolicyType{}
Function Get-ZPAPolicyTypeRules{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAPostureProfiles{}
Function Get-ZPAPostureProfile{}
Function Get-ZPAServiceEdges{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAServiceEdge{}
Function Edit-ZPAServiceEdge{}
Function New-ZPAServiceEdge{}
Function Remove-ZPAServiceEdge{}
Function Remove-ZPAServiceEdges{}
Function Get-ZPAServiceEdgeGroups{}
Function Get-ZPAServiceEdgeGroup{}
Function Edit-ZPAServiceEdgeGroup{}
Function New-ZPAServiceEdgeGroup{}
Function Remove-ZPAServiceEdgeGroup{}
Function Get-ZPASamlAttributes{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPASamlAttribute{}
Function Get-ZPASamlIDPAttributes{}
Function Get-ZPASCIMAttributes{}
Function Get-ZPASCIMAttribute{}
Function Get-ZPASCIMAttributeValues{}
Function Get-ZPASCIMGroups{}
Function Get-ZPASCIMGroup{}
Function Get-ZPAServerGroups{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAServerGroup{}
Function Edit-ZPAServerGroup{}
Function New-ZPAServerGroup{}
Function Remove-ZPAServerGroup{}
Function Get-ZPALSSConfigs{}
Function Get-ZPALSSConfig{}
Function New-ZPALSSConfig{}
Function Edit-ZPALSSConfig{}
Function Remove-ZPALSSConfig{}
Function Get-ZPALSSConfigLogFormats{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPALSSConfigClientTypes{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPALSSLogFormats{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPALSSStatusCodes{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAEnrollmentCerts{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPAEnrollmentCert{}
Function Get-ZPATrustedNetworks{
    <#
    .SYNOPSIS
        Gets all ############# for your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER customerid
        The unique identifier of your ZPA Tenant.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject] List of ##################

    .EXAMPLE
        $######### = Get-####### -token $token -customerid $customerid -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$customerid, # The unique identifier of your ZPA Tenant
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $apiurl = "$($zscalercloud)/mgmtconfig/v1/admin/customers/$($customerid)/###############"
    $response = Invoke-RestMethod -URI "$($apiurl)?page=1&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    IF($response.totalPages -eq "1"){
        return $response.list
    }ELSEIF($response.totalPages -gt "1"){
        $list = $response.list
        2..$($response.totalPages) | ForEach-Object{
            $list += (Invoke-RestMethod -URI "$($uri)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
        }
        return $list
    }ELSE{
        return $null
    }
}
Function Get-ZPATrustedNetwork{}


Function Get-ZPAAPIEndpoint{
    <#
    .SYNOPSIS
        Executes a GET request against your Tenant.

    .DESCRIPTION
        A function that returns a list of all ############### for your ZScaler ZPA Tenant

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER apiendpoint
        The api path you want to launch a GET request against.

    .OUTPUTS
        [System.Management.Automation.PSCustomObject]

    .EXAMPLE
        $data = Get-ZPAAPIEndpoint -token $token -customerid $customerid -apiendpoint "https://config.zpagov.net/mgmtconfig/v1/admin/customers/{customerId}/authDomains"

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated ZPA Token
        [Parameter(Mandatory, Position=1)]$apiendpoint # The ZScaler Cloud of your tenant
    )
    begin{
        $response = Invoke-RestMethod -URI $apiendpoint -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}
    }
    process{}
    end{return $response}
}


