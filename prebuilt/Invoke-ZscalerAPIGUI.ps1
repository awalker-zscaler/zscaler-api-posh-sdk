
Write-Host "`nBackup and Restore Utility" -ForegroundColor Red -NoNewline
Write-Host " - Public Sector Professional Services - " -NoNewline
Write-Host " ZSCALER`n`n" -ForegroundColor Cyan
Add-Type -AssemblyName System.Windows.Forms

# Show MIT License
Write-Host (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/awalker-zscaler/branding/main/LICENSE").content -ForegroundColor DarkGray

Function Invoke-WriteLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)][ValidateSet("CRITICAL","DANGER","WARNING","INFORM","SUCCESS","DEBUG")]$severity,
        [Parameter(Mandatory, Position=1)][string]$message
    )
    $logtable.ReadOnly = $false
    IF($severity -eq "CRITICAL"){
        Write-Host $("{0:HH:mm:ss:fff}:" -f (Get-Date)) -NoNewline -ForegroundColor DarkGray
        Write-Host " CRITICAL " -ForegroundColor DarkRed -NoNewline
        Write-Host " $message"
        $logtable.AppendText("`r`n" + "$("{0:HH:mm:ss:fff}:" -f (Get-Date)) CRITICAL  $message")
        $logtable.ScrollToCaret()
    }ELSEIF($severity -eq "DANGER"){
        Write-Host $("{0:HH:mm:ss:fff}:" -f (Get-Date)) -NoNewline -ForegroundColor DarkGray
        Write-Host " DANGER   " -ForegroundColor Red
        Write-Host " $message"
        $logtable.AppendText("`r`n" + "$("{0:HH:mm:ss:fff}:" -f (Get-Date)) DANGER    $message")
        $logtable.ScrollToCaret()
    }ELSEIF($severity -eq "WARNING"){
        Write-Host $("{0:HH:mm:ss:fff}:" -f (Get-Date)) -NoNewline -ForegroundColor DarkGray
        Write-Host " WARNING  " -ForegroundColor Yellow -NoNewline
        Write-Host " $message"
        $logtable.AppendText("`r`n" + "$("{0:HH:mm:ss:fff}:" -f (Get-Date)) WARNING   $message")
        $logtable.ScrollToCaret()
    }ELSEIF($severity -eq "INFORM"){
        Write-Host $("{0:HH:mm:ss:fff}:" -f (Get-Date)) -NoNewline -ForegroundColor DarkGray
        Write-Host " INFORM   " -ForegroundColor Blue -NoNewline
        Write-Host " $message"
        $logtable.AppendText("`r`n" + "$("{0:HH:mm:ss:fff}:" -f (Get-Date)) INFORM    $message")
        $logtable.ScrollToCaret()
    }ELSEIF($severity -eq "DEBUG" -and $settingsverboselog.checked){
        Write-Host $("{0:HH:mm:ss:fff}:" -f (Get-Date)) -NoNewline -ForegroundColor DarkGray
        Write-Host " DEBUG    " -ForegroundColor White -NoNewline
        Write-Host " $message"
        $logtable.AppendText("`r`n" + "$("{0:HH:mm:ss:fff}:" -f (Get-Date)) DEBUG     $message")
        $logtable.ScrollToCaret()
    }ELSEIF($severity -eq "SUCCESS"){
        Write-Host $("{0:HH:mm:ss:fff}:" -f (Get-Date)) -NoNewline -ForegroundColor DarkGray
        Write-Host " SUCCESS  " -ForegroundColor GREEN -NoNewline
        Write-Host " $message"
        $logtable.AppendText("`r`n" + "$("{0:HH:mm:ss:fff}:" -f (Get-Date)) SUCCESS   $message")
        $logtable.ScrollToCaret()
    }
    $logtable.ReadOnly = $true
    [System.Windows.Forms.Application]::DoEvents()
}
Function Invoke-ConfigBackup {
    $FileBrowser = New-Object System.Windows.Forms.SaveFileDialog 
    $FileBrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    $FileBrowser.Title = "Save Configuration File"
    $FileBrowser.filter = "XML Document|*.xml"
    $FileBrowser.AddExtension = "xml"
    $FileBrowser.ShowDialog()
    $path = $filebrowser.filename
    IF($null -ne $path){
        [PSCustomObject]@{
            ZPA = [PSCustomObject]@{
                Cloud = $settingscloud.Text
                Client_ID = $settingsclientid.Text
                Client_Secret = $settingsclientsecret.Text
                Customer_ID = $settingscustomerid.Text
            }
            ZIA = [PSCustomObject]@{
                Cloud = $settingsziaendpoint.text
                API_Key = $settingsziaapikey.text
                Username = $settingsziausername.text
                Password = $settingsziapassword.text
            }
        } | Export-Clixml -Depth 3 -Path $path
        Invoke-WriteLog INFORM "Saving configuration to $($path)"
    }else{
        return $false
    }
}
Function Invoke-ConfigLoad {
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
    $FileBrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    $FileBrowser.Title = "Load Configuration File"
    $FileBrowser.filter = "XML Document|*.xml"
    $FileBrowser.ShowDialog()
    $path = $filebrowser.filename
    IF($null -ne $path){
        $config = Import-Clixml -Path $path
        Invoke-WriteLog INFORM "Loading configuration from $($path)."
        $settingscloud.Text = $config.ZPA.cloud
        Invoke-WriteLog DEBUG "Setting ZPA API Host to $($config.ZPA.Cloud)."
        $settingsclientid.Text = $config.ZPA.Client_ID
        Invoke-WriteLog DEBUG "Setting Client ID to $($config.ZPA.Client_ID)."
        $settingsclientsecret.Text = $config.ZPA.client_secret
        Invoke-WriteLog DEBUG "Setting Client Secret to <redacted>."
        $settingscustomerid.Text = $config.ZPA.customer_id
        Invoke-WriteLog DEBUG "Setting Customer ID to $($config.ZPA.customer_id)."
        $settingsziaendpoint.text = $config.ZIA.cloud
        Invoke-WriteLog DEBUG "Setting ZIA API Host to $($config.ZPA.Cloud)."
        $settingsziaapikey.text = $config.ZIA.API_Key
        Invoke-WriteLog DEBUG "Setting API Key to $($config.ZIA.API_Key)."
        $settingsziausername.text = $config.ZIA.Username
        Invoke-WriteLog DEBUG "Setting API Key to $($config.ZIA.Username)."
        $settingsziapassword.text = $config.ZIA.Password
        Invoke-WriteLog DEBUG "Setting API Key to <redacted>."
    }else{
        return $false
    }

}
Function Invoke-ZIAAPILOGIN {
    <#
    .SYNOPSIS
        Authenticate against the ZIA API

    .DESCRIPTION
        A function that allows a user or script to log in to the ZScaler ZIA API on their tenant.

    .PARAMETER apikey
        Your client id.

    .PARAMETER username
        Your client secret. 

    .PARAMETER password
        Your client secret. 

    .PARAMETER baseurl
        The cloud that your tenant resides in.

    .OUTPUTS
        [PSCustomObject]@{
            type = ADMIN_LOGIN # Login Type; This script only supports Admin login.
            authenticated = TRUE # [BOOL] If the session is authenticated.
            websession = Microsoft.PowerShell.Commands.WebRequestSession # The session that will be used for other API calls.
        }

    .EXAMPLE
        $response = Invoke-ZIAAPILOGIN -apikey "2FAoJTp9UnWi" -username "user@example.com" -password 'S0m3cR@zYP@$5w0Rd' -baseurl zsapi.zscalergov.net/api/v1
        
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$apikey, # Your API Key
        [Parameter(Mandatory, Position=1)]$username, # Your Username
        [Parameter(Mandatory, Position=2)]$password, # Your Password
        [Parameter(Mandatory, Position=3)]$baseurl # The ZScaler Cloud of your tenant
    )
    # Create an authenticated web session
    $ziaws=new-object Microsoft.PowerShell.Commands.WebRequestSession

    function Invoke-ObfuscateApiKey {[CmdletBinding()]
        param(
            [Parameter(Mandatory, Position=0)]$apikey, # Your API Key
            [Parameter(Mandatory, Position=1)]$timestamp # UTC EPOCH Time
        )
        $high = $timestamp.substring($timestamp.length - 6)
        $low = ([int]$high -shr 1).toString()
        $obfuscatedApiKey = ''
        while ($low.length -lt 6) {$low = '0' + $low}
        for ($i = 0; $i -lt $high.length; $i++) {$obfuscatedApiKey += $apiKey[[int64]($high[$i].toString())]}
        for ($j = 0; $j -lt $low.length; $j++) {$obfuscatedApiKey += $apiKey[[int64]$low[$j].ToString() + 2]}
        return $obfuscatedApiKey
    }
    $timestamp = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()).tostring() # Get current UTC time in EPOCH Format
    $payload = @{
        apiKey=Invoke-ObfuscateApiKey -apiKey $apikey -timestamp $timestamp
        username=$username
        password=$password
        timestamp=$timestamp
    }  | ConvertTo-Json
    try {
        $response = Invoke-RestMethod -URI "https://$($baseurl)/api/v1/authenticatedSession" -WebSession $zia -Method POST -Body $payload -ContentType 'application/json' 
    }
    catch {
        Write-Warning ($Error[0].errordetails.message | ConvertFrom-JSON).message
        return [PSCustomObject]@{
            type = $response.authType
            authenticated = $false
            websession = $ziaws
        }
    }
    #  Validate
    IF($response.obfuscateApiKey){
        $auth = $true
    }ELSE{
        $auth = $false
    }
    return [PSCustomObject]@{
        type = $response.authType
        authenticated = $auth
        websession = $ziaws
    }
}
Function Invoke-ZIAAPILOGOUT{
    <#
    .SYNOPSIS
        Log out of the ZIA API

    .DESCRIPTION
        A function that allows a user or script to log out of the ZScaler ZIA API on their tenant.

    .PARAMETER websession
        The websession that was used when logging in. 

    .PARAMETER baseurl
        The cloud that your tenant resides in.

    .EXAMPLE
        Invoke-ZIAAPILOGOUT -websession $websession -baseurl zsapi.zscalergov.net/api/v1
        
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$websession, # The websession that you want to log out of.
        [Parameter(Mandatory, Position=1)]$baseurl # The ZScaler Cloud of your tenant
    )
    try {
        Invoke-RestMethod -URI "https://$($baseurl)/api/v1/authenticatedSession" -WebSession $websession -Method DELETE
    }
    catch {
    }
}
function Invoke-ZPAAPILOGIN {
    <#
    .SYNOPSIS
        Authenticate against the ZPA API

    .DESCRIPTION
        A function that allows a user or script to log in to the ZScaler ZPA API on their tenant.

    .PARAMETER clientid
        Your client id.

    .PARAMETER clientsecret
        Your client secret. 

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [PSCustomObject]@{
            type = # Type of Authentication used (token)
            expires = # The time the token expires
            authenticated = # [Boolean] If the token is authenticated; used for automated validation
            token = # The actual token to use in other functions
        }

    .EXAMPLE
        $response = Invoke-ZPAAPILOGIN -clientid "NzIwNTgwMzMMDYtYTU0ODdmNWUxOTgzMzM5ODMtYzEzZDZiZmQtN2FhZC00NTNhLWJj1OTg0" -clientsecret '}Na}U)mk[9K6]}]r*!+|FcQEd4b0m5w[' -zscalercloud "https://config.zpagov.net"

    .NOTES
        Due to the inclusion of the "-form" flag on line 51, this function requires Powershell 7.2+

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$clientid, # Your Client ID
        [Parameter(Mandatory, Position=1)]$clientsecret, # Your Client Secret
        [Parameter(Mandatory, Position=2)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    $parameters = @{ # Build form data
        client_id = $clientid # Your Client ID
        client_secret = $clientsecret # Your Client Secret
    }
    TRY{
        $response = (Invoke-RestMethod -Uri "https://$($zscalercloud)/signin" -Method Post -Form $parameters -ContentType '*/*') # Try and log in using the specified paramaters
    }CATCH{ # Catch any exceptions and control output
        Write-Warning "$(($Error[0].errordetails.message | ConvertFrom-JSON).id) - $(($Error[0].errordetails.message | ConvertFrom-JSON).reason)"
        return [PSCustomObject]@{
            type = $null
            expires = $null
            authenticated = $false
            token = $Error[0].Exception
        }
    }
    IF($null -ne $response.access_token){$auth = $true}else{$auth -eq $false} # Check and see if the token is present
    return [PSCustomObject]@{
        type = $response.token_type
        expires = (Get-Date).AddSeconds($($response.expires_in)).ToString("[yy.MM.dd HH:mm]")
        authenticated = $auth
        token = $response.access_token
    }
}
function Invoke-ZPAAPILOGOUT {
    <#
    .SYNOPSIS
        Logout of the ZPA API

    .DESCRIPTION
        A function that allows a user or script to log out of the ZScaler ZPA API on their tenant.

    .PARAMETER token
        The token that was returned on your authenticated session.

    .PARAMETER zscalercloud
        The cloud that your tenant resides in.

    .OUTPUTS
        [BOOL] TRUE # Successfully unauthenticated
        [BOOL] FALSE # Unable to logout

    .EXAMPLE
        $response = Invoke-ZPAAPILOGOUT -token "eyJraWQiOiJoUGFnTFFndzh....TRFhHXy1KUERpOHVhSVgyc3pJZFQ4Tm4t" -zscalercloud https://config.zpagov.net

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]$token, # Your Authenticated Token
        [Parameter(Mandatory, Position=1)]$zscalercloud # The ZScaler Cloud of your tenant
    )
    
    TRY{
        Invoke-RestMethod -Uri "https://$($zscalercloud)/signout" -Method Post -ContentType '*/*' -Headers @{ Authorization = "Bearer $token"}
    }CATCH{
        Write-Warning "$(($Error[0].errordetails.message | ConvertFrom-JSON).id) - $(($Error[0].errordetails.message | ConvertFrom-JSON).reason)"
        return $false
    }
    return $true
}

# Load Images
$global:zscaler_resources = [PSCustomObject]@{
    Settings = [PSCustomObject]@{
        hover = (Invoke-WebRequest "https://raw.githubusercontent.com/awalker-zscaler/branding/main/resources/images/settings-hover.png").content
        standard = (Invoke-WebRequest "https://raw.githubusercontent.com/awalker-zscaler/branding/main/resources/images/settings.png").content
    }
    Backup = [PSCustomObject]@{
        hover = (Invoke-WebRequest "https://raw.githubusercontent.com/awalker-zscaler/branding/main/resources/images/backup-hover.png").content
        standard = (Invoke-WebRequest "https://raw.githubusercontent.com/awalker-zscaler/branding/main/resources/images/backup.png").content
    }
    Restore = [PSCustomObject]@{
        hover = (Invoke-WebRequest "https://raw.githubusercontent.com/awalker-zscaler/branding/main/resources/images/restore-hover.png").content
        standard = (Invoke-WebRequest "https://raw.githubusercontent.com/awalker-zscaler/branding/main/resources/images/restore.png").content
    }
    Troubleshooting = [PSCustomObject]@{
        hover = (Invoke-WebRequest "https://raw.githubusercontent.com/awalker-zscaler/branding/main/resources/images/troubleshoot-hover.png").content
        standard = (Invoke-WebRequest "https://raw.githubusercontent.com/awalker-zscaler/branding/main/resources/images/troubleshoot.png").content
    }
    About = [PSCustomObject]@{
        hover = (Invoke-WebRequest "https://raw.githubusercontent.com/awalker-zscaler/branding/main/resources/images/about-hover.png").content
        standard = (Invoke-WebRequest "https://raw.githubusercontent.com/awalker-zscaler/branding/main/resources/images/about.png").content
    }
    Tools = [PSCustomObject]@{
        hover = (Invoke-WebRequest "https://raw.githubusercontent.com/awalker-zscaler/branding/main/resources/images/tools-hover.png").content
        standard = (Invoke-WebRequest "https://raw.githubusercontent.com/awalker-zscaler/branding/main/resources/images/tools.png").content
    }
    Icon = (Invoke-WebRequest -Uri "https://www.zscaler.com/favicon.ico").content
    Logo = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/awalker-zscaler/branding/main/resources/images/zscalerlogo.png").content
}


#region gui
# Create a new GUI
$mainwindow                    = New-Object system.Windows.Forms.Form
# Define the size, title and background color
$mainwindow.ClientSize         = '800,600'
$mainwindow.text               = "Zscaler - Backup and Restore Utility"
$mainwindow.BackColor          = "#009cda"
$mainwindow.FormBorderStyle    = "FixedSingle"
$mainwindow.StartPosition      = 'CenterScreen'
$mainwindow.Icon               = $global:zscaler_resources.icon
$mainwindow.MaximizeBox        = $false

# Create Whitespace
$bottomwindow                  = New-Object System.Windows.Forms.Panel
$bottomwindow.BackColor        = "White"
$bottomwindow.location         = New-Object System.Drawing.Point(-2,60)
$bottomwindow.width            = 804
$bottomwindow.height           = 542

# Set Logo
$logo = New-Object System.Windows.Forms.PictureBox
$logo.location         = New-Object System.Drawing.Point(26,10)
$logo.width            = 200
$logo.height           = 42
$logo.BackColor        = "#009cda"
$logo.BorderStyle      = "None"
$logo.Image = $global:zscaler_resources.logo

# Animations
Function Invoke-ButtonGlow {
    IF($settingspanel.visible -eq $false){
        $settingsbuttonpicture.BackgroundImage = $global:zscaler_resources.Settings.standard
        $settingsbuttonlabel.ForeColor  = "#000000"
    }
    IF($backuppanel.visible -eq $false){
        $backupbuttonpicture.BackgroundImage = $global:zscaler_resources.Backup.standard
        $backupbuttonlabel.ForeColor  = "#000000"
    }
    IF($restorepanel.visible -eq $false){
        $restorebuttonpicture.BackgroundImage = $global:zscaler_resources.Restore.standard
        $restorebuttonlabel.ForeColor  = "#000000"
    }
    IF($troubleshootingpanel.visible -eq $false){
        $troubleshootbuttonpicture.BackgroundImage = $global:zscaler_resources.Troubleshooting.standard
        $troubleshootbuttonlabel.ForeColor  = "#000000"
    }
    IF($toolboxpanel.visible -eq $false){
        $toolboxbuttonpicture.BackgroundImage = $global:zscaler_resources.Tools.standard
        $toolboxbuttonlabel.ForeColor  = "#000000"
    }
    IF($aboutpanel.visible -eq $false){
        $aboutbuttonpicture.BackgroundImage = $global:zscaler_resources.About.standard
        $aboutbuttonlabel.ForeColor  = "#000000"
    }
}

# Settings Button
Function Invoke-SettingsButton {
    $settingspanel.visible          = $true
    $backuppanel.visible            = $false
    $restorepanel.visible           = $false
    $troubleshootingpanel.visible   = $false
    $toolboxpanel.visible           = $false
    $aboutpanel.visible             = $false
    $homelabel.Visible              = $false
}

$settingsbuttonpicture = New-Object System.Windows.Forms.Button
$settingsbuttonpicture.location = New-Object System.Drawing.Point(39,35)
$settingsbuttonpicture.width    = 48
$settingsbuttonpicture.height   = 48
$settingsbuttonpicture.cursor   = "hand"
$settingsbuttonpicture.BackColor = "White"
$settingsbuttonpicture.BackgroundImageLayout = "Zoom"
$settingsbuttonpicture.FlatStyle = "Flat"
$settingsbuttonpicture.FlatAppearance.BorderColor = "White"
$settingsbuttonpicture.FlatAppearance.BorderSize = 0
$settingsbuttonpicture.FlatAppearance.MouseDownBackColor = "White"
$settingsbuttonpicture.FlatAppearance.MouseOverBackColor = "White"
$settingsbuttonpicture.BackgroundImage = $global:zscaler_resources.settings.standard
$settingsbuttonpicture.Add_Click({Invoke-SettingsButton})
$settingsbuttonpicture.Add_MouseEnter({ 
    $settingsbuttonpicture.BackgroundImage = $global:zscaler_resources.settings.hover
    $settingsbuttonlabel.ForeColor  = "#009cda"
 })
 $settingsbuttonpicture.Add_MouseLeave({ 
    Invoke-ButtonGlow{}
 })

$settingsbuttonlabel = New-Object System.Windows.Forms.Label
$settingsbuttonlabel.text       = "Settings"
$settingsbuttonlabel.location   = New-Object System.Drawing.Point(14,84)
$settingsbuttonlabel.width      = 95
$settingsbuttonlabel.height     = 15
$settingsbuttonlabel.cursor     = "hand"
$settingsbuttonlabel.TextAlign  = [System.Drawing.ContentAlignment]::MiddleCenter
$settingsbuttonlabel.AutoSize   = $False
$settingsbuttonlabel.ForeColor  = "#000000"
$settingsbuttonlabel.Add_Click({Invoke-SettingsButton})
$settingsbuttonlabel.Add_MouseEnter({ 
    $settingsbuttonpicture.BackgroundImage = $global:zscaler_resources.settings.hover
    $settingsbuttonlabel.ForeColor  = "#009cda"
 })
 $settingsbuttonlabel.Add_MouseLeave({ 
    Invoke-ButtonGlow{}
 })

 # Backup Button
Function Invoke-BackupButton {
    $settingspanel.visible          = $false
    $backuppanel.visible            = $true
    $restorepanel.visible           = $false
    $troubleshootingpanel.visible   = $false
    $toolboxpanel.visible           = $false
    $aboutpanel.visible             = $false
    $homelabel.Visible              = $false
}

$backupbuttonpicture = New-Object System.Windows.Forms.Button
$backupbuttonpicture.location = New-Object System.Drawing.Point(39,116)
$backupbuttonpicture.width    = 48
$backupbuttonpicture.height   = 48
$backupbuttonpicture.cursor   = "hand"
$backupbuttonpicture.BackColor = "White"
$backupbuttonpicture.BackgroundImageLayout = "Zoom"
$backupbuttonpicture.FlatStyle = "Flat"
$backupbuttonpicture.FlatAppearance.BorderColor = "White"
$backupbuttonpicture.FlatAppearance.BorderSize = 0
$backupbuttonpicture.FlatAppearance.MouseDownBackColor = "White"
$backupbuttonpicture.FlatAppearance.MouseOverBackColor = "White"
$backupbuttonpicture.BackgroundImage = $global:zscaler_resources.backup.standard
$backupbuttonpicture.Add_Click({Invoke-BackupButton})
$backupbuttonpicture.Add_MouseEnter({ 
    $backupbuttonpicture.BackgroundImage = $global:zscaler_resources.backup.hover
    $backupbuttonlabel.ForeColor  = "#009cda"
 })
 $backupbuttonpicture.Add_MouseLeave({ 
    Invoke-ButtonGlow{}
 })

$backupbuttonlabel = New-Object System.Windows.Forms.Label
$backupbuttonlabel.text       = "Backup"
$backupbuttonlabel.location   = New-Object System.Drawing.Point(14,165)
$backupbuttonlabel.width      = 95
$backupbuttonlabel.height     = 15
$backupbuttonlabel.cursor     = "hand"
$backupbuttonlabel.TextAlign  = [System.Drawing.ContentAlignment]::MiddleCenter
$backupbuttonlabel.AutoSize   = $False
$backupbuttonlabel.ForeColor  = "#000000"
$backupbuttonlabel.Add_Click({Invoke-BackupButton})
$backupbuttonlabel.Add_MouseEnter({ 
$backupbuttonpicture.BackgroundImage = $global:zscaler_resources.backup.hover
$backupbuttonlabel.ForeColor  = "#009cda"
})
$backupbuttonlabel.Add_MouseLeave({ 
    Invoke-ButtonGlow{}
})

# Restore Button
Function Invoke-RestoreButton {
    $settingspanel.visible          = $false
    $backuppanel.visible            = $false
    $restorepanel.visible           = $true
    $troubleshootingpanel.visible   = $false
    $toolboxpanel.visible           = $false
    $aboutpanel.visible             = $false
    $homelabel.Visible              = $false
}

$restorebuttonpicture = New-Object System.Windows.Forms.Button
$restorebuttonpicture.location = New-Object System.Drawing.Point(39,197)
$restorebuttonpicture.width    = 48
$restorebuttonpicture.height   = 48
$restorebuttonpicture.cursor   = "hand"
$restorebuttonpicture.BackColor = "White"
$restorebuttonpicture.BackgroundImageLayout = "Zoom"
$restorebuttonpicture.FlatStyle = "Flat"
$restorebuttonpicture.FlatAppearance.BorderColor = "White"
$restorebuttonpicture.FlatAppearance.BorderSize = 0
$restorebuttonpicture.FlatAppearance.MouseDownBackColor = "White"
$restorebuttonpicture.FlatAppearance.MouseOverBackColor = "White"
$restorebuttonpicture.BackgroundImage = $global:zscaler_resources.Restore.standard
$restorebuttonpicture.Add_Click({Invoke-RestoreButton})
$restorebuttonpicture.Add_MouseEnter({ 
    $restorebuttonpicture.BackgroundImage = $global:zscaler_resources.Restore.hover
    $restorebuttonlabel.ForeColor  = "#009cda"
})
$restorebuttonpicture.Add_MouseLeave({ 
    Invoke-ButtonGlow{}
})

$restorebuttonlabel = New-Object System.Windows.Forms.Label
$restorebuttonlabel.text       = "Restore"
$restorebuttonlabel.location   = New-Object System.Drawing.Point(14,246)
$restorebuttonlabel.width      = 95
$restorebuttonlabel.height     = 15
$restorebuttonlabel.cursor     = "hand"
$restorebuttonlabel.TextAlign  = [System.Drawing.ContentAlignment]::MiddleCenter
$restorebuttonlabel.AutoSize   = $False
$restorebuttonlabel.ForeColor  = "#000000"
$restorebuttonlabel.Add_Click({Invoke-RestoreButton})
$restorebuttonlabel.Add_MouseEnter({ 
    $restorebuttonpicture.BackgroundImage = $global:zscaler_resources.Restore.hover
    $restorebuttonlabel.ForeColor  = "#009cda"
})
$restorebuttonlabel.Add_MouseLeave({ 
    Invoke-ButtonGlow{}
})

# Troubleshoot Button
Function Invoke-TroubleshootButton {
    $settingspanel.visible          = $false
    $backuppanel.visible            = $false
    $restorepanel.visible           = $false
    $troubleshootingpanel.visible   = $true
    $toolboxpanel.visible           = $false
    $aboutpanel.visible             = $false
    $homelabel.Visible              = $false
}

$troubleshootbuttonpicture = New-Object System.Windows.Forms.Button
$troubleshootbuttonpicture.location = New-Object System.Drawing.Point(39,278)
$troubleshootbuttonpicture.width    = 48
$troubleshootbuttonpicture.height   = 48
$troubleshootbuttonpicture.cursor   = "hand"
$troubleshootbuttonpicture.BackColor = "White"
$troubleshootbuttonpicture.BackgroundImageLayout = "Zoom"
$troubleshootbuttonpicture.FlatStyle = "Flat"
$troubleshootbuttonpicture.FlatAppearance.BorderColor = "White"
$troubleshootbuttonpicture.FlatAppearance.BorderSize = 0
$troubleshootbuttonpicture.FlatAppearance.MouseDownBackColor = "White"
$troubleshootbuttonpicture.FlatAppearance.MouseOverBackColor = "White"
$troubleshootbuttonpicture.BackgroundImage = $global:zscaler_resources.Troubleshooting.standard
$troubleshootbuttonpicture.Add_Click({Invoke-TroubleshootButton})
$troubleshootbuttonpicture.Add_MouseEnter({ 
    $troubleshootbuttonpicture.BackgroundImage = $global:zscaler_resources.Troubleshooting.hover
    $troubleshootbuttonlabel.ForeColor  = "#009cda"
})
$troubleshootbuttonpicture.Add_MouseLeave({ 
    Invoke-ButtonGlow{}
})

$troubleshootbuttonlabel = New-Object System.Windows.Forms.Label
$troubleshootbuttonlabel.text       = "Troubleshooting"
$troubleshootbuttonlabel.location   = New-Object System.Drawing.Point(14,327)
$troubleshootbuttonlabel.width      = 95
$troubleshootbuttonlabel.height     = 15
$troubleshootbuttonlabel.cursor     = "hand"
$troubleshootbuttonlabel.TextAlign  = [System.Drawing.ContentAlignment]::MiddleCenter
$troubleshootbuttonlabel.AutoSize   = $False
$troubleshootbuttonlabel.ForeColor  = "#000000"
$troubleshootbuttonlabel.Add_Click({Invoke-TroubleshootButton})
$troubleshootbuttonlabel.Add_MouseEnter({ 
    $troubleshootbuttonpicture.BackgroundImage = $global:zscaler_resources.Troubleshooting.hover
    $troubleshootbuttonlabel.ForeColor  = "#009cda"
})
$troubleshootbuttonlabel.Add_MouseLeave({ 
    Invoke-ButtonGlow{}
})

# Toolbox Button
Function Invoke-ToolboxButton {
    $settingspanel.visible          = $false
    $backuppanel.visible            = $false
    $restorepanel.visible           = $false
    $troubleshootingpanel.visible   = $false
    $toolboxpanel.visible           = $true
    $aboutpanel.visible             = $false
    $homelabel.Visible              = $false
}

$toolboxbuttonpicture = New-Object System.Windows.Forms.Button
$toolboxbuttonpicture.location = New-Object System.Drawing.Point(39,359)
$toolboxbuttonpicture.width    = 48
$toolboxbuttonpicture.height   = 48
$toolboxbuttonpicture.cursor   = "hand"
$toolboxbuttonpicture.BackColor = "White"
$toolboxbuttonpicture.BackgroundImageLayout = "Zoom"
$toolboxbuttonpicture.FlatStyle = "Flat"
$toolboxbuttonpicture.FlatAppearance.BorderColor = "White"
$toolboxbuttonpicture.FlatAppearance.BorderSize = 0
$toolboxbuttonpicture.FlatAppearance.MouseDownBackColor = "White"
$toolboxbuttonpicture.FlatAppearance.MouseOverBackColor = "White"
$toolboxbuttonpicture.BackgroundImage = $global:zscaler_resources.Tools.standard
$toolboxbuttonpicture.Add_Click({Invoke-ToolboxButton})
$toolboxbuttonpicture.Add_MouseEnter({ 
    $toolboxbuttonpicture.BackgroundImage = $global:zscaler_resources.Tools.hover
    $toolboxbuttonlabel.ForeColor  = "#009cda"
})
$toolboxbuttonpicture.Add_MouseLeave({ 
    Invoke-ButtonGlow{}
})

$toolboxbuttonlabel = New-Object System.Windows.Forms.Label
$toolboxbuttonlabel.text       = "Toolbox"
$toolboxbuttonlabel.location   = New-Object System.Drawing.Point(14,408)
$toolboxbuttonlabel.width      = 95
$toolboxbuttonlabel.height     = 15
$toolboxbuttonlabel.cursor     = "hand"
$toolboxbuttonlabel.TextAlign  = [System.Drawing.ContentAlignment]::MiddleCenter
$toolboxbuttonlabel.AutoSize   = $False
$toolboxbuttonlabel.ForeColor  = "#000000"
$toolboxbuttonlabel.Add_Click({Invoke-ToolboxButton})
$toolboxbuttonlabel.Add_MouseEnter({ 
    $toolboxbuttonpicture.BackgroundImage = $global:zscaler_resources.Tools.hover
    $toolboxbuttonlabel.ForeColor  = "#009cda"
})
$toolboxbuttonlabel.Add_MouseLeave({ 
    Invoke-ButtonGlow{}
})

# About Button
Function Invoke-AboutButton {
    $settingspanel.visible          = $false
    $backuppanel.visible            = $false
    $restorepanel.visible           = $false
    $troubleshootingpanel.visible   = $false
    $toolboxpanel.visible           = $false
    $aboutpanel.visible             = $true
    $homelabel.Visible              = $false
}

$aboutbuttonpicture = New-Object System.Windows.Forms.Button
$aboutbuttonpicture.location = New-Object System.Drawing.Point(39,440)
$aboutbuttonpicture.width    = 48
$aboutbuttonpicture.height   = 48
$aboutbuttonpicture.cursor   = "hand"
$aboutbuttonpicture.BackColor = "White"
$aboutbuttonpicture.BackgroundImageLayout = "Zoom"
$aboutbuttonpicture.FlatStyle = "Flat"
$aboutbuttonpicture.FlatAppearance.BorderColor = "White"
$aboutbuttonpicture.FlatAppearance.BorderSize = 0
$aboutbuttonpicture.FlatAppearance.MouseDownBackColor = "White"
$aboutbuttonpicture.FlatAppearance.MouseOverBackColor = "White"
$aboutbuttonpicture.BackgroundImage = $global:zscaler_resources.About.hover
$aboutbuttonpicture.Add_Click({Invoke-AboutButton})
$aboutbuttonpicture.Add_MouseEnter({ 
    $aboutbuttonpicture.BackgroundImage = $global:zscaler_resources.About.hover
    $aboutbuttonlabel.ForeColor  = "#009cda"
})
$aboutbuttonpicture.Add_MouseLeave({ 
    Invoke-ButtonGlow{}
})

$aboutbuttonlabel = New-Object System.Windows.Forms.Label
$aboutbuttonlabel.text       = "About"
$aboutbuttonlabel.location   = New-Object System.Drawing.Point(14,489)
$aboutbuttonlabel.width      = 95
$aboutbuttonlabel.height     = 15
$aboutbuttonlabel.cursor     = "hand"
$aboutbuttonlabel.ForeColor  = "#009cda"
$aboutbuttonlabel.TextAlign  = [System.Drawing.ContentAlignment]::MiddleCenter
$aboutbuttonlabel.AutoSize   = $False
$aboutbuttonlabel.ForeColor  = "#009cda"
$aboutbuttonlabel.Add_Click({Invoke-AboutButton})
$aboutbuttonlabel.Add_MouseEnter({ 
    $aboutbuttonpicture.BackgroundImage = $global:zscaler_resources.About.hover
    $aboutbuttonlabel.ForeColor  = "#009cda"
})
$aboutbuttonlabel.Add_MouseLeave({ 
    Invoke-ButtonGlow{}
})
#endregion gui

#region settings
# Settings Panel
$settingspanel                  = New-Object System.Windows.Forms.Panel
$settingspanel.location         = New-Object System.Drawing.Point(115,10)
$settingspanel.width            = 680
$settingspanel.height           = 520
$settingspanel.autosize         = $false
$settingspanel.Visible          = $false
$settingspanel.BackColor        = "white"
# Settings Title
$settingstitle                  = New-Object System.Windows.Forms.Label
$settingstitle.location         = New-Object System.Drawing.Point(0,0)
$settingstitle.width            = 678
$settingstitle.height           = 25
$settingstitle.TextAlign        = [System.Drawing.ContentAlignment]::MiddleCenter
$settingstitle.AutoSize         = $False
$settingstitle.text             = "Application Settings"
$settingstitle.font             = [System.Drawing.Font]::new("Arial", 12)
# Settings Controls
# ZPA Settings
$settingszpalabel = New-Object System.Windows.Forms.Label
$settingszpalabel.text       = "ZPA API Settings"
$settingszpalabel.AutoSize   = $false
$settingszpalabel.font       = [System.Drawing.Font]::new("Segoe UI", 9.75, [System.Drawing.FontStyle]::Underline)
$settingszpalabel.location   = New-Object System.Drawing.Point(31,36)
$settingszpalabel.width      = 115
$settingszpalabel.height     = 17
# Cloud Dropdown
$settingscloud = New-object System.Windows.Forms.ComboBox
$settingscloud.Items.Insert(0,"config.private.zscaler.com")
$settingscloud.Items.Insert(1,"config.zpagov.net")
$settingscloud.location        = New-Object System.Drawing.Point(122,62)
$settingscloud.width           = 181
$settingscloud.height          = 23
# Cloud Dropdown Label
$settingscloudlabel = New-Object System.Windows.Forms.Label
$settingscloudlabel.AutoSize   = $false
$settingscloudlabel.text       = "API Endpoint : "
$settingscloudlabel.location   = New-Object System.Drawing.Point(31,62)
$settingscloudlabel.width      = 85
$settingscloudlabel.height     = 23
# Client ID Textbox
$settingsclientid = New-Object System.Windows.Forms.TextBox
$settingsclientid.location = New-Object System.Drawing.Point(122,91)
$settingsclientid.width    = 181
$settingsclientid.height   = 23
# Client ID Label
$settingsclientidlabel = New-Object System.Windows.Forms.Label
$settingsclientidlabel.AutoSize   = $false
$settingsclientidlabel.text     = "Client ID : "
$settingsclientidlabel.location = New-Object System.Drawing.Point(31,90)
$settingsclientidlabel.width    = 85
$settingsclientidlabel.height   = 23
# Client Secret Textbox
$settingsclientsecret = New-Object System.Windows.Forms.TextBox
$settingsclientsecret.location = New-Object System.Drawing.Point(122,120)
$settingsclientsecret.width    = 181
$settingsclientsecret.height   = 23
$settingsclientsecret.UseSystemPasswordChar = $true
# Client Secret Label
$settingsclientsecretlabel = New-Object System.Windows.Forms.Label
$settingsclientsecretlabel.AutoSize = $false
$settingsclientsecretlabel.text     = "Client Secret : "
$settingsclientsecretlabel.location = New-Object System.Drawing.Point(31,120)
$settingsclientsecretlabel.width    = 82
$settingsclientsecretlabel.height   = 23
# Customer ID Textbox
$settingscustomerid = New-Object System.Windows.Forms.TextBox
$settingscustomerid.location = New-Object System.Drawing.Point(122,149)
$settingscustomerid.width    = 181
$settingscustomerid.height   = 23
# Customer ID Label
$settingscustomeridlabel = New-Object System.Windows.Forms.Label
$settingscustomeridlabel.AutoSize = $false
$settingscustomeridlabel.text     = "Customer ID : "
$settingscustomeridlabel.location = New-Object System.Drawing.Point(31,149)
$settingscustomeridlabel.width    = 82
$settingscustomeridlabel.height   = 15
# Test ZPA Authentication Button
$settingstestzpabutton = New-Object System.Windows.Forms.Button
$settingstestzpabutton.text = "Test ZPA Authentication"
$settingstestzpabutton.Location = New-Object System.Drawing.Point(34,178)
$settingstestzpabutton.Width = 269
$settingstestzpabutton.Height = 23
$settingstestzpabutton.FlatStyle = "flat"
$settingstestzpabutton.FlatAppearance.BorderSize = 0
$settingstestzpabutton.BackColor = "#009cda"
$settingstestzpabutton.ForeColor = "White"
$settingstestzpabutton.Add_Click({
    IF("" -ne $settingscloud.text -and "" -ne $settingsclientid.text -and "" -ne $settingsclientsecret.text -and "" -ne $settingscustomerid.text){
        Invoke-WriteLog -severity INFORM -message "Attempting to validate ZPA Credentials."
        $zpatest = Invoke-ZPAAPILOGIN -clientid $settingsclientid.text -clientsecret $settingsclientsecret.text -zscalercloud $settingscloud.text
        IF($zpatest.authenticated){
            Invoke-WriteLog -severity INFORM -message "Authentication Successful."
            [System.Windows.Forms.MessageBox]::Show('You were able to log in to the ZPA API using the provided credentials.','SUCCESS','Ok',0) | Out-Null
        }ELSE{            
            Invoke-WriteLog -severity INFORM -message "Authentication Unsuccessful. Check credentials and connectivity."
        }
        Invoke-ZPAAPILOGOUT -token $zpatest.token -zscalercloud $settingscloud.text

    }ELSE{
        [System.Windows.Forms.MessageBox]::Show('Please make sure you have populated the ZPA settings for authentication.','Not enough information','Ok','Error') | Out-Null
    }
})
# ZIA Settings
$settingszialabel = New-Object System.Windows.Forms.Label
$settingszialabel.text       = "ZIA API Settings"
$settingszialabel.AutoSize   = $false
$settingszialabel.font       = [System.Drawing.Font]::new("Segoe UI", 9.75, [System.Drawing.FontStyle]::Underline)
$settingszialabel.location   = New-Object System.Drawing.Point(377,36)
$settingszialabel.width      = 115
$settingszialabel.height     = 17
# Endpoint Dropdown
$settingsziaendpoint = New-object System.Windows.Forms.ComboBox
$settingsziaendpoint.Items.Insert(0,"zsapi.zscalergov.net")
$settingsziaendpoint.Items.Insert(1,"zsapi.zscalerbeta.net")
$settingsziaendpoint.Items.Insert(2,"zsapi.zscalerone.net")
$settingsziaendpoint.Items.Insert(3,"zsapi.zscalertwo.net")
$settingsziaendpoint.Items.Insert(4,"zsapi.zscalerthree.net")
$settingsziaendpoint.Items.Insert(5,"zsapi.zscaler.net")
$settingsziaendpoint.Items.Insert(6,"zsapi.zscloud.net")
$settingsziaendpoint.location        = New-Object System.Drawing.Point(468,62)
$settingsziaendpoint.width           = 181
$settingsziaendpoint.height          = 23
# Endpoint Dropdown Label
$settingsziaendpointlabel = New-Object System.Windows.Forms.Label
$settingsziaendpointlabel.AutoSize   = $false
$settingsziaendpointlabel.text       = "API Endpoint : "
$settingsziaendpointlabel.location   = New-Object System.Drawing.Point(377,62)
$settingsziaendpointlabel.width      = 85
$settingsziaendpointlabel.height     = 23
# API Key Textbox
$settingsziaapikey = New-Object System.Windows.Forms.TextBox
$settingsziaapikey.location = New-Object System.Drawing.Point(468,91)
$settingsziaapikey.width    = 181
$settingsziaapikey.height   = 23
# API Key Label
$settingsziaapikeylabel = New-Object System.Windows.Forms.Label
$settingsziaapikeylabel.AutoSize   = $false
$settingsziaapikeylabel.text     = "API Key : "
$settingsziaapikeylabel.location = New-Object System.Drawing.Point(377,90)
$settingsziaapikeylabel.width    = 85
$settingsziaapikeylabel.height   = 23
# Username Textbox
$settingsziausername = New-Object System.Windows.Forms.TextBox
$settingsziausername.location = New-Object System.Drawing.Point(468,120)
$settingsziausername.width    = 181
$settingsziausername.height   = 23
# Username Label
$settingsziausernamelabel = New-Object System.Windows.Forms.Label
$settingsziausernamelabel.AutoSize = $false
$settingsziausernamelabel.text     = "Username : "
$settingsziausernamelabel.location = New-Object System.Drawing.Point(377,120)
$settingsziausernamelabel.width    = 82
$settingsziausernamelabel.height   = 23
# Password Textbox
$settingsziapassword = New-Object System.Windows.Forms.TextBox
$settingsziapassword.location = New-Object System.Drawing.Point(468,149)
$settingsziapassword.width    = 181
$settingsziapassword.height   = 23
$settingsziapassword.UseSystemPasswordChar = $true
# Password Label
$settingsziapasswordlabel = New-Object System.Windows.Forms.Label
$settingsziapasswordlabel.AutoSize = $false
$settingsziapasswordlabel.text     = "Password : "
$settingsziapasswordlabel.location = New-Object System.Drawing.Point(377,149)
$settingsziapasswordlabel.width    = 82
$settingsziapasswordlabel.height   = 15
# Test ZIA Authentication Button
$settingstestziabutton = New-Object System.Windows.Forms.Button
$settingstestziabutton.text = "Test ZIA Authentication"
$settingstestziabutton.Location = New-Object System.Drawing.Point(380,178)
$settingstestziabutton.Width = 269
$settingstestziabutton.Height = 23
$settingstestziabutton.FlatStyle = "flat"
$settingstestziabutton.FlatAppearance.BorderSize = 0
$settingstestziabutton.BackColor = "#009cda"
$settingstestziabutton.ForeColor = "White"
$settingstestziabutton.Add_Click({
    IF("" -ne $settingsziaendpoint.text -and "" -ne $settingsziaapikey.text -and "" -ne $settingsziausername.text -and "" -ne $settingsziapassword.text){
        Invoke-WriteLog -severity INFORM -message "Attempting to validate ZIA Credentials."
        $ziatest = Invoke-ZIAAPILOGIN -apikey $settingsziaapikey.text -username $settingsziausername.text -password $settingsziapassword.text -baseurl $settingsziaendpoint.text
        IF($ziatest.authenticated){
            Invoke-WriteLog -severity INFORM -message "Authentication Successful."
            [System.Windows.Forms.MessageBox]::Show('You were able to log in to the ZIA API using the provided credentials.','SUCCESS','Ok',0) | Out-Null
        }ELSE{            
            Invoke-WriteLog -severity INFORM -message "Authentication Unsuccessful. Check credentials and connectivity."
        }
        Invoke-ZIAAPILOGOUT -websession $ziatest.websession -baseurl $settingsziaendpoint.text | Out-Null

    }ELSE{
        [System.Windows.Forms.MessageBox]::Show('Please make sure you have populated the ZIA settings for authentication.','Not enough information','Ok','Error') | Out-Null
    }
})
# Save Configuration Button
$settingssavebutton = New-Object System.Windows.Forms.Button
$settingssavebutton.text = "Save Configuration"
$settingssavebutton.Location = New-Object System.Drawing.Point(209,444)
$settingssavebutton.Width = 135
$settingssavebutton.Height = 23
$settingssavebutton.FlatStyle = "flat"
$settingssavebutton.FlatAppearance.BorderSize = 0
$settingssavebutton.BackColor = "#009cda"
$settingssavebutton.ForeColor = "White"
$settingssavebutton.Add_Click({Invoke-ConfigBackup})
# Load Configuration Button
$settingsloadbutton = New-Object System.Windows.Forms.Button
$settingsloadbutton.text = "Load Configuration"
$settingsloadbutton.Location = New-Object System.Drawing.Point(350,444)
$settingsloadbutton.Width = 135
$settingsloadbutton.Height = 23
$settingsloadbutton.FlatStyle = "flat"
$settingsloadbutton.FlatAppearance.BorderSize = 0
$settingsloadbutton.BackColor = "#009cda"
$settingsloadbutton.ForeColor = "White"
$settingsloadbutton.Add_Click({Invoke-ConfigLoad})
# Logging Debug Toggle
$settingsverboselog = New-Object System.Windows.Forms.CheckBox
$settingsverboselog.Text = "Verbose Logging"
$settingsverboselog.Location = New-Object System.Drawing.Point(52,390)
$settingsverboselog.Width = 120
$settingsverboselog.Height = 19
# Add items to settings panel
$settingspanel.Controls.AddRange(@($settingstitle,$settingscloud,$settingscloudlabel,$settingsclientid,$settingsclientidlabel,$settingscustomerid,$settingscustomeridlabel,$settingsclientsecret,$settingsclientsecretlabel,$settingsverboselog,$settingsloadbutton,$settingssavebutton,$settingszpalabel,$settingstestzpabutton,$settingstestziabutton,$settingsziapasswordlabel,$settingsziapassword,$settingsziausernamelabel,$settingsziausername,$settingsziaapikeylabel,$settingsziaapikey,$settingsziaendpoint,$settingszialabel,$settingsziaendpointlabel))
#endregion settings

#region backup
# Backup Panel
$backuppanel                  = New-Object System.Windows.Forms.Panel
$backuppanel.location         = New-Object System.Drawing.Point(115,10)
$backuppanel.width            = 680
$backuppanel.height           = 520
$backuppanel.autosize         = $false
$backuppanel.Visible          = $false
$backuppanel.BackColor        = "white"
# Backup Title
$backuptitle                  = New-Object System.Windows.Forms.Label
$backuptitle.location         = New-Object System.Drawing.Point(0,0)
$backuptitle.width            = 678
$backuptitle.height           = 25
$backuptitle.TextAlign        = [System.Drawing.ContentAlignment]::MiddleCenter
$backuptitle.AutoSize         = $False
$backuptitle.text             = "Configuration Backup"
$backuptitle.font             = [System.Drawing.Font]::new("Arial", 12)
# Backup Controls
# Save Location Label
$backuplocationlabel = New-Object System.Windows.Forms.Label
$backuplocationlabel.text     = "Save Location : "
$backuplocationlabel.location = New-Object System.Drawing.Point(6,54)
$backuplocationlabel.width    = 89
$backuplocationlabel.height   = 15

# Save Location Label
$backuplocation = New-Object System.Windows.Forms.Label
$backuplocation.text     = "$([Environment]::GetFolderPath('Desktop'))\backup.xml"
$backuplocation.location = New-Object System.Drawing.Point(29,73)
$backuplocation.width    = 400
$backuplocation.height   = 15

# Backup Location Button
$backuplocationbutton = New-Object System.Windows.Forms.Button
$backuplocationbutton.text = "Browse"
$backuplocationbutton.Location = New-Object System.Drawing.Point(381,53)
$backuplocationbutton.Width = 75
$backuplocationbutton.Height = 20
$backuplocationbutton.FlatStyle = "flat"
$backuplocationbutton.FlatAppearance.BorderSize = 0
$backuplocationbutton.BackColor = "#009cda"
$backuplocationbutton.ForeColor = "White"
$backuplocationbutton.Add_Click({
    $FileBrowser = New-Object System.Windows.Forms.SaveFileDialog 
    $FileBrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    $FileBrowser.Title = "Save Configuration File"
    $FileBrowser.filter = "XML Document|*.xml"
    $fileBrowser.DefaultExt = "xml"
    $FileBrowser.AddExtension = "xml"
    $FileBrowser.ShowDialog()
    $path = $filebrowser.filename
    IF($null -ne $path){
        Invoke-WriteLog DEBUG "Changing backup path to $($FileBrowser.FileName)"
        $backuplocation.text = $FileBrowser.FileName
    }else{
        Invoke-WriteLog CRITICAL "No valid path was selected. Please try again."
    }
})

# ZPA Backup Toggle
$zpabackuptoggle = New-Object System.Windows.Forms.CheckBox
$zpabackuptoggle.Text = "ZPA Configuration"
$zpabackuptoggle.Location = New-Object System.Drawing.Point(7,97)
$zpabackuptoggle.Width = 124
$zpabackuptoggle.Height = 19

# ZIA Backup Toggle
$ziabackuptoggle = New-Object System.Windows.Forms.CheckBox
$ziabackuptoggle.Text = "ZIA Configuration"
$ziabackuptoggle.Location = New-Object System.Drawing.Point(7,122)
$ziabackuptoggle.Width = 124
$ziabackuptoggle.Height = 19
$ziabackuptoggle.Enabled = $false

# Backup Button
$backupbutton = New-Object System.Windows.Forms.Button
$backupbutton.text = "Start Backup"
$backupbutton.Location = New-Object System.Drawing.Point(303,183)
$backupbutton.Width = 125
$backupbutton.Height = 35
$backupbutton.FlatStyle = "flat"
$backupbutton.FlatAppearance.BorderSize = 0
$backupbutton.BackColor = "#009cda"
$backupbutton.ForeColor = "White"
$backupbutton.Add_Click({
    $backupbutton.text = "Processing"
    $backupbutton.enabled = $false
    IF($zpabackuptoggle.Checked -and $ziabackuptoggle.Checked){
        $global:zpabackups = Invoke-ZPABACKUP -clientid $settingsclientid.text -clientsecret $settingsclientsecret.text -zscalercloud $settingscloud.text
        Invoke-WriteLog INFORM "ZIA Backup is not currently implemented."
        $backupbutton.text = "Start Backup"
        $backupbutton.enabled = $true
    }ELSEIF($zpabackuptoggle.checked){
        $global:zpabackups = Invoke-ZPABACKUP -clientid $settingsclientid.text -clientsecret $settingsclientsecret.text -zscalercloud $settingscloud.text
        $backupbutton.text = "Start Backup"
        $backupbutton.enabled = $true
    }ELSEIF($ziabackuptoggle.checked){
        Invoke-WriteLog INFORM "ZIA Backup is not currently implemented."
        $backupbutton.text = "Start Backup"
        $backupbutton.enabled = $true
    }ELSE{
        Invoke-WriteLog INFORM "You have not selected a target to backup.  Please check a box and try again. "
        $backupbutton.text = "Start Backup"
        $backupbutton.enabled = $true
    }
    IF($null -ne $global:zpabackups -or $null -ne $global:ziabackups){
        Invoke-WriteLog INFORM "Saving backup to $($backuplocation.text) "
        @(
            $global:zpabackups,
            $global:ziabackups
        ) | Export-Clixml -depth 15 -Path $backuplocation.text -Force
    }
})
# Add items to backup panel
$backuppanel.Controls.AddRange(@($backuptitle,$backuplocation,$backuplocationlabel,$backuplocationbutton,$ziabackuptoggle,$zpabackuptoggle,$backupbutton))

#endregion backup

#region restore
# Restore Panel
$restorepanel                  = New-Object System.Windows.Forms.Panel
$restorepanel.location         = New-Object System.Drawing.Point(115,10)
$restorepanel.width            = 680
$restorepanel.height           = 520
$restorepanel.autosize         = $false
$restorepanel.Visible          = $false
$restorepanel.BackColor        = "white"
# Restore Title
$restoretitle                  = New-Object System.Windows.Forms.Label
$restoretitle.location         = New-Object System.Drawing.Point(0,0)
$restoretitle.width            = 678
$restoretitle.height           = 25
$restoretitle.TextAlign        = [System.Drawing.ContentAlignment]::MiddleCenter
$restoretitle.AutoSize         = $False
$restoretitle.text             = "Configuration Restoration"
$restoretitle.font             = [System.Drawing.Font]::new("Arial", 12)

# Add items to backup panel
$restorepanel.Controls.AddRange(@($restoretitle))
#endregion restore

#region troubleshooting
# Troubleshooting Panel
$troubleshootingpanel                  = New-Object System.Windows.Forms.Panel
$troubleshootingpanel.location         = New-Object System.Drawing.Point(115,10)
$troubleshootingpanel.width            = 680
$troubleshootingpanel.height           = 520
$troubleshootingpanel.autosize         = $false
$troubleshootingpanel.Visible          = $false
$troubleshootingpanel.BackColor        = "white"
# Troubleshooting Title
$troubleshootingtitle                  = New-Object System.Windows.Forms.Label
$troubleshootingtitle.location         = New-Object System.Drawing.Point(0,0)
$troubleshootingtitle.width            = 678
$troubleshootingtitle.height           = 25
$troubleshootingtitle.TextAlign        = [System.Drawing.ContentAlignment]::MiddleCenter
$troubleshootingtitle.AutoSize         = $False
$troubleshootingtitle.text             = "Troubleshooting - Activity Logs"
$troubleshootingtitle.font             = [System.Drawing.Font]::new("Arial", 12)
# Troubleshooting Table
$logtable = New-Object System.Windows.Forms.RichTextBox
$logtable.location         = New-Object System.Drawing.Point(4,36)
$logtable.width            = 657
$logtable.height           = 402
$logtable.BorderStyle      = "FixedSingle"
$logtable.text             = "TIME          SEVERITY  MESSAGE"
$logtable.ReadOnly         = $true
$logtable.ScrollBars       = "ForcedBoth"
$logtable.WordWrap         = $false
$logtable.font             = [System.Drawing.Font]::new("Courier New", 9)
# Log Control Buttons
$logexportbutton = New-Object System.Windows.Forms.Button
$logexportbutton.text = "Export Logs"
$logexportbutton.Location = New-Object System.Drawing.Point(526,440)
$logexportbutton.Width = 135
$logexportbutton.Height = 23
$logexportbutton.FlatStyle = "flat"
$logexportbutton.FlatAppearance.BorderSize = 0
$logexportbutton.BackColor = "#009cda"
$logexportbutton.ForeColor = "White"
$logexportbutton.Add_Click({
    $logexport = New-Object System.Windows.Forms.SaveFileDialog 
    $logexport.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    $logexport.Title = "Save Configuration File"
    $logexport.filter = "Text Document|*.txt"
    $logexport.AddExtension = "txt"
    $logexport.ShowDialog()
    $path = $logexport.filename
    IF($path -ne $null){
        $logtable.text | Out-File -FilePath $path
    }
})
$logclearbutton = New-Object System.Windows.Forms.Button
$logclearbutton.text = "Clear Logs"
$logclearbutton.Location = New-Object System.Drawing.Point(385,440)
$logclearbutton.Width = 135
$logclearbutton.Height = 23
$logclearbutton.FlatStyle = "flat"
$logclearbutton.FlatAppearance.BorderSize = 0
$logclearbutton.BackColor = "#009cda"
$logclearbutton.ForeColor = "White"
$logclearbutton.Add_Click({
    IF([System.Windows.Forms.MessageBox]::Show('Are you sure you want to clear the log table?','Are you sure?','YesNo','Warning') -eq "Yes"){
        $logtable.text             = "TIME          SEVERITY  MESSAGE"
    }    
})



# Add items to backup panel
$troubleshootingpanel.Controls.AddRange(@($troubleshootingtitle,$logtable,$logclearbutton,$logexportbutton))
#endregion troubleshooting

#region toolbox
# Toolbox Panel
$toolboxpanel                  = New-Object System.Windows.Forms.Panel
$toolboxpanel.location         = New-Object System.Drawing.Point(115,10)
$toolboxpanel.width            = 680
$toolboxpanel.height           = 520
$toolboxpanel.autosize         = $false
$toolboxpanel.Visible          = $false
$toolboxpanel.BackColor        = "white"
# Toolbox Title
$toolboxtitle                  = New-Object System.Windows.Forms.Label
$toolboxtitle.location         = New-Object System.Drawing.Point(0,0)
$toolboxtitle.width            = 678
$toolboxtitle.height           = 25
$toolboxtitle.TextAlign        = [System.Drawing.ContentAlignment]::MiddleCenter
$toolboxtitle.AutoSize         = $False
$toolboxtitle.text             = "Zscaler Toolbox - Functions and Scripts"
$toolboxtitle.font             = [System.Drawing.Font]::new("Arial", 12)
# Toolbox Tabs
$toolboxtabcontrol = New-Object System.Windows.Forms.TabControl
$toolboxtabcontrol.location         = New-Object System.Drawing.Point(18,28)
$toolboxtabcontrol.width            = 663
$toolboxtabcontrol.height           = 481
$toolboxtabcontrol.autosize         = $false
$toolboxtabcontrol.BackColor        = "white"
# ZPA Tools Tab
$toolboxtabzpa = New-Object System.Windows.Forms.TabPage
$toolboxtabzpa.text = "ZPA Tools"
$toolboxtabzpa.BackColor        = "white"

$toolszpaconnectorstatus = New-Object System.Windows.Forms.Button
$toolszpaconnectorstatus.text = "Connector Status"
$toolszpaconnectorstatus.Location = New-Object System.Drawing.Point(6,6)
$toolszpaconnectorstatus.Width = 112
$toolszpaconnectorstatus.Height = 23
$toolszpaconnectorstatus.FlatStyle = "flat"
$toolszpaconnectorstatus.FlatAppearance.BorderSize = 0
$toolszpaconnectorstatus.BackColor = "#009cda"
$toolszpaconnectorstatus.ForeColor = "White"
$toolszpaconnectorstatus.Add_Click({})

$toolszpaidpvalidation = New-Object System.Windows.Forms.Button
$toolszpaidpvalidation.text = "IDP Validation"
$toolszpaidpvalidation.Location = New-Object System.Drawing.Point(6,35)
$toolszpaidpvalidation.Width = 112
$toolszpaidpvalidation.Height = 23
$toolszpaidpvalidation.FlatStyle = "flat"
$toolszpaidpvalidation.FlatAppearance.BorderSize = 0
$toolszpaidpvalidation.BackColor = "#009cda"
$toolszpaidpvalidation.ForeColor = "White"
$toolszpaidpvalidation.Add_Click({})

$toolszparulesearch = New-Object System.Windows.Forms.Button
$toolszparulesearch.text = "Rule Search"
$toolszparulesearch.Location = New-Object System.Drawing.Point(6,64)
$toolszparulesearch.Width = 112
$toolszparulesearch.Height = 23
$toolszparulesearch.FlatStyle = "flat"
$toolszparulesearch.FlatAppearance.BorderSize = 0
$toolszparulesearch.BackColor = "#009cda"
$toolszparulesearch.ForeColor = "White"
$toolszparulesearch.Add_Click({})

$toolboxtabzpa.Controls.AddRange(@($toolszpaconnectorstatus,$toolszpaidpvalidation,$toolszparulesearch))
# ZIA Tools Tab
$toolboxtabzia = New-Object System.Windows.Forms.TabPage
$toolboxtabzia.text = "ZIA Tools"
$toolboxtabzia.BackColor        = "white"
# ZDX Tools Tab
$toolboxtabzdx = New-Object System.Windows.Forms.TabPage
$toolboxtabzdx.text = "ZDX Tools"
$toolboxtabzdx.BackColor        = "white"
# ZCC Tools Tab
$toolboxtabzcc = New-Object System.Windows.Forms.TabPage
$toolboxtabzcc.text = "ZCC Tools"
$toolboxtabzcc.BackColor        = "white"
# User Tools Tab
$toolboxtabuser = New-Object System.Windows.Forms.TabPage
$toolboxtabuser.text = "User Tools"
$toolboxtabuser.BackColor        = "white"
# Misc Tools Tab
$toolboxtabmisc = New-Object System.Windows.Forms.TabPage
$toolboxtabmisc.text = "Misc. Tools"
$toolboxtabmisc.BackColor        = "white"
# Add tabs to tabcontrol
$toolboxtabcontrol.TabPages.AddRange(@($toolboxtabzpa,$toolboxtabzia,$toolboxtabzdx,$toolboxtabzcc,$toolboxtabuser,$toolboxtabmisc))
# Add items to backup panel
$toolboxpanel.Controls.AddRange(@($toolboxtitle,$toolboxtabcontrol))
#endregion toolbox

#region about
# About Panel
$aboutpanel                  = New-Object System.Windows.Forms.Panel
$aboutpanel.location         = New-Object System.Drawing.Point(115,10)
$aboutpanel.width            = 680
$aboutpanel.height           = 520
$aboutpanel.autosize         = $false
$aboutpanel.Visible          = $true
$aboutpanel.BackColor        = "white"
# About Title
$abouttitle                  = New-Object System.Windows.Forms.Label
$abouttitle.location         = New-Object System.Drawing.Point(0,0)
$abouttitle.width            = 678
$abouttitle.height           = 25
$abouttitle.TextAlign        = [System.Drawing.ContentAlignment]::MiddleCenter
$abouttitle.AutoSize         = $False
$abouttitle.text             = "About"
$abouttitle.font             = [System.Drawing.Font]::new("Arial", 12)

# About Page Content
$abouttext = New-Object System.Windows.Forms.Label
$abouttext.text = "Backup and Restore Tool

This tool is a collection of scripts and functions to facilitate backup, restore, and troubleshooting 
efforts in a centralized location.  In order to use this tool, you will require information to be populated
on the settings page.  

Once the settings page is filled out, you can move on to other areas.  To minimize the level of effort when
reusing the tool in the future, the configuration can be saved for each tenant for simple loading. 

The backup page provides tools to backup your ZPA and ZIA configurations.  

The restore page allows you to take an existing backup and restore your configuration to the settings
located within that backup.  If you have a backup that contains both ZPA and ZIA settings, you can choose
which one you want to back up, or both.  

The troubleshooting page gives you common tools to validate this app's configuration and quickly find common 
errors. 

The toolbox will give you the ability to do batch uploads, advanced queries, and rule searches.  

The about page tells you about this application. 
"
$abouttext.location   = New-Object System.Drawing.Point(6,40)
$abouttext.width      = 660
$abouttext.height     = 344
$abouttext.autosize = $false

# Add items to backup panel
$aboutpanel.Controls.AddRange(@($abouttitle, $abouttext))
#endregion about

# THIS SHOULD BE AT THE END OF YOUR SCRIPT FOR NOW
$bottomwindow.Controls.AddRange(@($homelabel,$settingsbuttonpicture,$settingsbuttonlabel,$backupbuttonpicture,$backupbuttonlabel,$restorebuttonpicture,$restorebuttonlabel,$troubleshootbuttonpicture,$troubleshootbuttonlabel,$toolboxbuttonpicture,$toolboxbuttonlabel,$aboutbuttonpicture,$aboutbuttonlabel,$settingspanel, $backuppanel, $restorepanel, $troubleshootingpanel, $toolboxpanel, $aboutpanel))
$mainwindow.Controls.AddRange(@($logo,$bottomwindow))

# Display the form
[void]$mainwindow.ShowDialog()
