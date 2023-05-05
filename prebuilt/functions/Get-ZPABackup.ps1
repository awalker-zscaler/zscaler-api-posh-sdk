Function Get-ZPABackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]$clientid, # Your Client ID
        [Parameter(Mandatory, Position = 1)]$clientsecret, # Your Client Secret
        [Parameter(Mandatory, Position = 2)]$zscalercloud, # The ZScaler Cloud of your tenant
        [Parameter(Mandatory, Position = 2)]$customerid # The ID of your tenant
    )
    begin{
        # Establish Log Files
        $logs = @()
        # SubFunctions
        function Invoke-ZPAAPILOGIN {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory, Position = 0)]$clientid, # Your Client ID
                [Parameter(Mandatory, Position = 1)]$clientsecret, # Your Client Secret
                [Parameter(Mandatory, Position = 2)]$zscalercloud # The ZScaler Cloud of your tenant
            )
            $parameters = @{ # Build form data
                client_id     = $clientid # Your Client ID
                client_secret = $clientsecret # Your Client Secret
            }
            TRY {
                $response = (Invoke-RestMethod -Uri "$($zscalercloud)/signin" -Method Post -Form $parameters -ContentType '*/*') # Try and log in using the specified paramaters
            }
            CATCH {
                # Catch any exceptions and control output
                Write-Warning "$(($Error[0].errordetails.message | ConvertFrom-JSON).id) - $(($Error[0].errordetails.message | ConvertFrom-JSON).reason)"
                return [PSCustomObject]@{
                    type          = $null
                    expires       = $null
                    authenticated = $false
                    token         = $Error[0].Exception
                }
            }
            IF ($null -ne $response.access_token) { $auth = $true }else { $auth -eq $false } # Check and see if the token is present
            return [PSCustomObject]@{
                type          = $response.token_type
                expires       = (Get-Date).AddSeconds($($response.expires_in)).ToString("[yy.MM.dd HH:mm]")
                authenticated = $auth
                token         = $response.access_token
            }
        }
        function Invoke-ZPAAPILOGOUT {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory, Position = 0)]$token, # Your Authenticated Token
                [Parameter(Mandatory, Position = 1)]$zscalercloud # The ZScaler Cloud of your tenant
            )
            
            TRY {
                Invoke-RestMethod -Uri "$($zscalercloud)/signout" -Method Post -ContentType '*/*' -Headers @{ Authorization = "Bearer $token" }
            }
            CATCH {
                Write-Warning "$(($Error[0].errordetails.message | ConvertFrom-JSON).id) - $(($Error[0].errordetails.message | ConvertFrom-JSON).reason)"
                return $false
            }
            return $true
        }
        Function Invoke-ZPASWAGGER {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory, Position = 0)]$token, # Your Authenticated ZPA Token
                [Parameter(Mandatory, Position = 1)]$zscalercloud # The ZScaler Cloud of your tenant
            )
            $response_raw = (Invoke-WebRequest -Uri "$($zscalercloud)/v2/customSwagger?tag=mgmtconfig" -Method GET -Headers @{ Authorization = "Bearer $token" } )
            $response = $response_raw.content | ConvertFrom-Json -AsHashtable
            $zpaswagger = @()
            0..$($response.paths.count - 1) | ForEach-Object {
                $zpaswagger += [PSCustomObject]@{
                    path        = $response.paths.keys[$_]
                    method      = $response.paths.values[$_].keys
                    tags        = $response.paths.values[$_].values.values[0]
                    summary     = $response.paths.values[$_].values.values[1]
                    operationId = $response.paths.values[$_].values.values[2]
                    produces    = $response.paths.values[$_].values.values[3]
                    responses   = $response.paths.values[$_].values.values[4]
                    deprecated  = $response.paths.values[$_].values.values[5]
                }
            }  
            return $zpaswagger
        }
        Function Get-ZPAAPIEndpoint {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory, Position = 0)]$token, # Your Authenticated ZPA Token
                [Parameter(Mandatory, Position = 1)]$apiendpoint # The ZScaler Cloud of your tenant
            )
            begin {
                $response = Invoke-RestMethod -URI $apiendpoint -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token" }
            }
            process {
                IF($response.totalPages -eq "1"){
                    $list = $response.list
                }ELSEIF($response.totalPages -gt "1"){
                    $list = $response.list
                    2..$($response.totalPages) | ForEach-Object{
                        $list += (Invoke-RestMethod -URI "$($apiendpoint)?page=$($_)&pagesize=50" -Method Get -ContentType "*/*" -Headers @{ Authorization = "Bearer $token"}).list
                    }
                }
            }
            end { 
                return $list
            }
        }
        Function Write-LocalLog {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory, Position = 0)]$severity, 
                [Parameter(Mandatory, Position = 1)]$category,
                [Parameter(Mandatory, Position = 2)]$message
            )
            Write-Host "$(Get-Date -Format o) - $severity - $category : $message"
            return [PSCustomObject]@{
                TimeStamp = $(Get-Date -Format o)
                Severity = $severity
                Category = $category
                Message = $message
            }

        }
        $logs += Write-LocalLog -severity "DEBUG" -category "Authentication" -message "Attempting to authenticate against the Zscaler ZPA API."
        $loginattempt = Invoke-ZPAAPILOGIN -clientid $clientid -clientsecret $clientsecret -zscalercloud $zscalercloud
        IF($loginattempt.authenticated){
            $logs += Write-LocalLog -severity "INFORM" -category "Authentication" -message "Authenticated."
            $logs += Write-LocalLog -severity "DEBUG" -category "Authentication" -message "$($loginattempt.type) authentication expires $($loginattempt.expires)"
            $token = $loginattempt.token
            $logintime = $(Get-Date -Format o)
        }ELSE{
            $logs += Write-LocalLog -severity "CRITICAL" -category "Authentication" -message "Unable to authenticate. Verify credentials, cloud, and connectivity."
            return $logs
        }
        
    }
    process{
        $logs += Write-LocalLog -severity "INFORM" -category "Swagger" -message "Getting all Zscaler API Calls from Swagger."
        $swagger = Invoke-ZPASwagger -token $token -zscalercloud $zscalercloud
        $logs += Write-LocalLog -severity "DEBUG" -category "Swagger" -message "Received $($swagger.count) methods."
        $backups = @()
        $logs += Write-LocalLog -severity "INFORM" -category "Backups" -message "Starting Backup Collection."
        $swagger | Where-Object {$_.method -like "*get*" -and $_.path -notlike "*d}"} | ForEach-Object {
            $logs += Write-LocalLog -severity "DEBUG" -category $_.tags -message "$($_.operationId) - $($_.summary)"
            $path = $_.path.replace("{customerId}",$customerid)
            IF($_.operationId -eq "getPolicySetByPolicyTypeUsingGET_1"){
                $data = [PSCustomObject]@{
                    Access = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{policyType}","ACCESS_POLICY"))"
                    Timeout = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{policyType}","TIMEOUT_POLICY"))"
                    SIEM = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{policyType}","SIEM_POLICY"))"
                    Forwarding = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{policyType}","CLIENT_FORWARDING_POLICY"))"
                    Inspection = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{policyType}","INSPECTION_POLICY"))"
                    Credential = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{policyType}","CREDENTIAL_POLICY"))"
                    Capabilities = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{policyType}","CAPABILITIES_POLICY"))"
                }

            }ELSEIF($_.operationId -eq "getAllSCIMAttributesUsingGET_1"){
                $data = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)/mgmtconfig/v2/admin/customers/$($customerid)/samlAttribute" | ForEach-Object {
                    IF($null -ne $_.idpId){
                        Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{idpId}",$_.idpId))"
                    }                    
                }

            }ELSEIF($_.operationId -eq "getProvisioningKeyForAssociationTypeUsingGET_1"){
                $data = [PSCustomObject]@{
                    ConnectorGroup = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{associationType}","CONNECTOR_GRP"))"
                    ServiceEdgeGroup = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{associationType}","SERVICE_EDGE_GRP"))"
                }

            }ELSEIF($_.operationId -eq "getPolicyRulesByPageUsingGET_1"){
                $data = [PSCustomObject]@{
                    Access = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{policyType}","ACCESS_POLICY"))"
                    Timeout = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{policyType}","TIMEOUT_POLICY"))"
                    SIEM = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{policyType}","SIEM_POLICY"))"
                    Forwarding = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{policyType}","CLIENT_FORWARDING_POLICY"))"
                    Inspection = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{policyType}","INSPECTION_POLICY"))"
                    Credential = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{policyType}","CREDENTIAL_POLICY"))"
                    Capabilities = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path.replace("{policyType}","CAPABILITIES_POLICY"))"
                }

            }ELSEIF($_.operationId -eq "getAllInspectionControlsUsingGET"){
                # Ignored for now.
            }ELSEIF($_.operationId -eq "getProfileInfoUsingGET"){
                # Ignored for now.
            }ELSE{
                $data = Get-ZPAAPIEndpoint -token $token -apiendpoint "$($zscalercloud)$($path)"
            }
            $logs += Write-LocalLog -severity "DEBUG" -category $_.tags -message "$($data.count) records found."
            $backups += [PSCustomObject]@{
                Name = $_.operationId
                Tags = $_.tags
                Summary = $_.summary
                Data = $data
            }
        }

    }
    end{
        $logs += Write-LocalLog -severity "DEBUG" -category "Authentication" -message "Logging out of the Zscaler ZPA API"
        Invoke-ZPAAPILOGOUT -token $token -zscalercloud $zscalercloud | Out-Null
        $logs += Write-LocalLog -severity "INFORM" -category "Authentication" -message "Logged out of the Zscaler ZPA API"
        $logouttime = $(Get-Date -Format o)
        return [PSCustomObject]@{
            Authentication = [PSCustomObject]@{
                LoginTime = $logintime
                TokenExpiration = $loginattempt.expires
                LogoutTime = $logouttime
                LoginType = $loginattempt.type
            }
            Logs = $logs
            Backups = $backups
        }
    }
}
