Write-Host "`nZSCALER " -ForegroundColor Cyan -NoNewline
Write-Host " - Public Sector Professional Services - " -NoNewline
Write-Host " Backup and Restore Utility`n`n" -ForegroundColor Red
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
            ZPAHost = $settingscloud.Text
            Client_ID = $settingsclientid.Text
            Client_Secret = $settingsclientsecret.Text
            Customer_ID = $settingscustomerid.Text
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
        Invoke-WriteLog INFORM "Loading configuration from $($path)"
        $global:zscaler.ZPAEnvironment.ZPAhost = $config.ZPAHost
        $settingscloud.Text = $config.ZPAHost
        Invoke-WriteLog DEBUG "Setting ZPA API Host to $($config.ZPAHost)"
        $global:zscaler.ZPAEnvironment.client_id = $config.Client_ID
        $settingsclientid.Text = $config.Client_ID
        Invoke-WriteLog DEBUG "Setting Client ID to $($config.Client_ID)"
        $global:zscaler.ZPAEnvironment.client_secret = $config.client_secret
        $settingsclientsecret.Text = $config.client_secret
        Invoke-WriteLog DEBUG "Setting Client Secret to $($config.client_secret)"
        $global:zscaler.ZPAEnvironment.customer_id = $config.customer_id
        $settingscustomerid.Text = $config.customer_id
        Invoke-WriteLog DEBUG "Setting Customer ID to $($config.customer_id)"
    }else{
        return $false
    }

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
    Start-Sleep 0.2
    $settingsbuttonpicture.BackgroundImage = $global:zscaler_resources.settings.standard
    $settingsbuttonlabel.ForeColor  = "#000000"
 })

$settingsbuttonlabel = New-Object System.Windows.Forms.Label
$settingsbuttonlabel.text       = "Settings"
$settingsbuttonlabel.location   = New-Object System.Drawing.Point(14,84)
$settingsbuttonlabel.width      = 95
$settingsbuttonlabel.height     = 15
$settingsbuttonlabel.cursor     = "hand"
$settingsbuttonlabel.ForeColor  = "#009cda"
$settingsbuttonlabel.TextAlign  = [System.Drawing.ContentAlignment]::MiddleCenter
$settingsbuttonlabel.AutoSize   = $False
$settingsbuttonlabel.ForeColor  = "#000000"
$settingsbuttonlabel.Add_Click({Invoke-SettingsButton})
$settingsbuttonlabel.Add_MouseEnter({ 
    $settingsbuttonpicture.BackgroundImage = $global:zscaler_resources.settings.hover
    $settingsbuttonlabel.ForeColor  = "#009cda"
 })
 $settingsbuttonlabel.Add_MouseLeave({ 
    Start-Sleep 0.2
    $settingsbuttonpicture.BackgroundImage = $global:zscaler_resources.settings.standard
    $settingsbuttonlabel.ForeColor  = "#000000"
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
    Start-Sleep 0.2
    $backupbuttonpicture.BackgroundImage = $global:zscaler_resources.backup.standard
    $backupbuttonlabel.ForeColor  = "#000000"
 })

$backupbuttonlabel = New-Object System.Windows.Forms.Label
$backupbuttonlabel.text       = "Backup"
$backupbuttonlabel.location   = New-Object System.Drawing.Point(14,165)
$backupbuttonlabel.width      = 95
$backupbuttonlabel.height     = 15
$backupbuttonlabel.cursor     = "hand"
$backupbuttonlabel.ForeColor  = "#009cda"
$backupbuttonlabel.TextAlign  = [System.Drawing.ContentAlignment]::MiddleCenter
$backupbuttonlabel.AutoSize   = $False
$backupbuttonlabel.ForeColor  = "#000000"
$backupbuttonlabel.Add_Click({Invoke-BackupButton})
$backupbuttonlabel.Add_MouseEnter({ 
$backupbuttonpicture.BackgroundImage = $global:zscaler_resources.backup.hover
$backupbuttonlabel.ForeColor  = "#009cda"
})
$backupbuttonlabel.Add_MouseLeave({ 
Start-Sleep 0.2
$backupbuttonpicture.BackgroundImage = $global:zscaler_resources.backup.standard
$backupbuttonlabel.ForeColor  = "#000000"
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
    Start-Sleep 0.2
    $restorebuttonpicture.BackgroundImage = $global:zscaler_resources.Restore.standard
    $restorebuttonlabel.ForeColor  = "#000000"
})

$restorebuttonlabel = New-Object System.Windows.Forms.Label
$restorebuttonlabel.text       = "Restore"
$restorebuttonlabel.location   = New-Object System.Drawing.Point(14,246)
$restorebuttonlabel.width      = 95
$restorebuttonlabel.height     = 15
$restorebuttonlabel.cursor     = "hand"
$restorebuttonlabel.ForeColor  = "#009cda"
$restorebuttonlabel.TextAlign  = [System.Drawing.ContentAlignment]::MiddleCenter
$restorebuttonlabel.AutoSize   = $False
$restorebuttonlabel.ForeColor  = "#000000"
$restorebuttonlabel.Add_Click({Invoke-RestoreButton})
$restorebuttonlabel.Add_MouseEnter({ 
    $restorebuttonpicture.BackgroundImage = $global:zscaler_resources.Restore.hover
    $restorebuttonlabel.ForeColor  = "#009cda"
})
$restorebuttonlabel.Add_MouseLeave({ 
    Start-Sleep 0.2
    $restorebuttonpicture.BackgroundImage = $global:zscaler_resources.Restore.standard
    $restorebuttonlabel.ForeColor  = "#000000"
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
    Start-Sleep 0.2
    $troubleshootbuttonpicture.BackgroundImage = $global:zscaler_resources.Troubleshooting.standard
    $troubleshootbuttonlabel.ForeColor  = "#000000"
})

$troubleshootbuttonlabel = New-Object System.Windows.Forms.Label
$troubleshootbuttonlabel.text       = "Troubleshooting"
$troubleshootbuttonlabel.location   = New-Object System.Drawing.Point(14,327)
$troubleshootbuttonlabel.width      = 95
$troubleshootbuttonlabel.height     = 15
$troubleshootbuttonlabel.cursor     = "hand"
$troubleshootbuttonlabel.ForeColor  = "#009cda"
$troubleshootbuttonlabel.TextAlign  = [System.Drawing.ContentAlignment]::MiddleCenter
$troubleshootbuttonlabel.AutoSize   = $False
$troubleshootbuttonlabel.ForeColor  = "#000000"
$troubleshootbuttonlabel.Add_Click({Invoke-TroubleshootButton})
$troubleshootbuttonlabel.Add_MouseEnter({ 
    $troubleshootbuttonpicture.BackgroundImage = $global:zscaler_resources.Troubleshooting.hover
    $troubleshootbuttonlabel.ForeColor  = "#009cda"
})
$troubleshootbuttonlabel.Add_MouseLeave({ 
    Start-Sleep 0.2
    $troubleshootbuttonpicture.BackgroundImage = $global:zscaler_resources.Troubleshooting.standard
    $troubleshootbuttonlabel.ForeColor  = "#000000"
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
    Start-Sleep 0.2
    $toolboxbuttonpicture.BackgroundImage = $global:zscaler_resources.Tools.standard
    $toolboxbuttonlabel.ForeColor  = "#000000"
})

$toolboxbuttonlabel = New-Object System.Windows.Forms.Label
$toolboxbuttonlabel.text       = "Toolbox"
$toolboxbuttonlabel.location   = New-Object System.Drawing.Point(14,408)
$toolboxbuttonlabel.width      = 95
$toolboxbuttonlabel.height     = 15
$toolboxbuttonlabel.cursor     = "hand"
$toolboxbuttonlabel.ForeColor  = "#009cda"
$toolboxbuttonlabel.TextAlign  = [System.Drawing.ContentAlignment]::MiddleCenter
$toolboxbuttonlabel.AutoSize   = $False
$toolboxbuttonlabel.ForeColor  = "#000000"
$toolboxbuttonlabel.Add_Click({Invoke-ToolboxButton})
$toolboxbuttonlabel.Add_MouseEnter({ 
    $toolboxbuttonpicture.BackgroundImage = $global:zscaler_resources.Tools.hover
    $toolboxbuttonlabel.ForeColor  = "#009cda"
})
$toolboxbuttonlabel.Add_MouseLeave({ 
    Start-Sleep 0.2
    $toolboxbuttonpicture.BackgroundImage = $global:zscaler_resources.Tools.standard
    $toolboxbuttonlabel.ForeColor  = "#000000"
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
$aboutbuttonpicture.BackgroundImage = $global:zscaler_resources.About.standard
$aboutbuttonpicture.Add_Click({Invoke-AboutButton})
$aboutbuttonpicture.Add_MouseEnter({ 
    $aboutbuttonpicture.BackgroundImage = $global:zscaler_resources.About.hover
    $aboutbuttonlabel.ForeColor  = "#009cda"
})
$aboutbuttonpicture.Add_MouseLeave({ 
    Start-Sleep 0.2
    $aboutbuttonpicture.BackgroundImage = $global:zscaler_resources.About.standard
    $aboutbuttonlabel.ForeColor  = "#000000"
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
$aboutbuttonlabel.ForeColor  = "#000000"
$aboutbuttonlabel.Add_Click({Invoke-AboutButton})
$aboutbuttonlabel.Add_MouseEnter({ 
    $aboutbuttonpicture.BackgroundImage = $global:zscaler_resources.About.hover
    $aboutbuttonlabel.ForeColor  = "#009cda"
})
$aboutbuttonlabel.Add_MouseLeave({ 
    Start-Sleep 0.2
    $aboutbuttonpicture.BackgroundImage = $global:zscaler_resources.About.standard
    $aboutbuttonlabel.ForeColor  = "#000000"
})

$homelabel = New-Object System.Windows.Forms.Label
$homelabel.text = "Backup and Restore Tool

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
$homelabel.location   = New-Object System.Drawing.Point(150,80)
$homelabel.width      = 620
$homelabel.height     = 440
$homelabel.autosize = $false
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
$settingscloud.Items.Insert(0,"https://config.zpagov.net")
$settingscloud.SelectedItem = "https://config.zpagov.net"
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
$settingsclientidlabel.text     = "Client ID : "
$settingsclientidlabel.location = New-Object System.Drawing.Point(146,83)
$settingsclientidlabel.width    = 61
$settingsclientidlabel.height   = 15
# Client Secret Textbox
$settingsclientsecret = New-Object System.Windows.Forms.TextBox
$settingsclientsecret.location = New-Object System.Drawing.Point(213,109)
$settingsclientsecret.width    = 242
$settingsclientsecret.height   = 23
# Client Secret Label
$settingsclientsecretlabel = New-Object System.Windows.Forms.Label
$settingsclientsecretlabel.text     = "Client Secret : "
$settingsclientsecretlabel.location = New-Object System.Drawing.Point(125,112)
$settingsclientsecretlabel.width    = 82
$settingsclientsecretlabel.height   = 15
# Customer ID Textbox
$settingscustomerid = New-Object System.Windows.Forms.TextBox
$settingscustomerid.location = New-Object System.Drawing.Point(213,138)
$settingscustomerid.width    = 242
$settingscustomerid.height   = 23
# Customer ID Label
$settingscustomeridlabel = New-Object System.Windows.Forms.Label
$settingscustomeridlabel.text     = "Customer ID : "
$settingscustomeridlabel.location = New-Object System.Drawing.Point(125,141)
$settingscustomeridlabel.width    = 82
$settingscustomeridlabel.height   = 15
# Save Configuration Button
$settingssavebutton = New-Object System.Windows.Forms.Button
$settingssavebutton.text = "Save Configuration"
$settingssavebutton.Location = New-Object System.Drawing.Point(105,192)
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
$settingsloadbutton.Location = New-Object System.Drawing.Point(246,192)
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
$settingsverboselog.Location = New-Object System.Drawing.Point(180,169)
$settingsverboselog.Width = 118
$settingsverboselog.Height = 19
# Add items to settings panel
$settingspanel.Controls.AddRange(@($settingstitle,$settingscloud,$settingscloudlabel,$settingsclientid,$settingsclientidlabel,$settingscustomerid,$settingscustomeridlabel,$settingsclientsecret,$settingsclientsecretlabel,$settingsverboselog,$settingsloadbutton,$settingssavebutton,$settingszpalabel))
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
        Invoke-ZPABACKUP
        Invoke-WriteLog INFORM "ZIA Backup is not currently implemented."
        $backupbutton.text = "Start Backup"
        $backupbutton.enabled = $true
    }ELSEIF($zpabackuptoggle.checked){
        Invoke-ZPABACKUP
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
$troubleshootingtitle.text             = "Troubleshooting"
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
$toolboxtitle.text             = "Zscaler Toolbox"
$toolboxtitle.font             = [System.Drawing.Font]::new("Arial", 12)

# Add items to backup panel
$toolboxpanel.Controls.AddRange(@($toolboxtitle))
#endregion toolbox

#region about
# About Panel
$aboutpanel                  = New-Object System.Windows.Forms.Panel
$aboutpanel.location         = New-Object System.Drawing.Point(115,10)
$aboutpanel.width            = 680
$aboutpanel.height           = 520
$aboutpanel.autosize         = $false
$aboutpanel.Visible          = $false
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

# Add items to backup panel
$aboutpanel.Controls.AddRange(@($abouttitle))
#endregion about

$bottomwindow.Controls.AddRange(@($homelabel,$settingsbuttonpicture,$settingsbuttonlabel,$backupbuttonpicture,$backupbuttonlabel,$restorebuttonpicture,$restorebuttonlabel,$troubleshootbuttonpicture,$troubleshootbuttonlabel,$toolboxbuttonpicture,$toolboxbuttonlabel,$aboutbuttonpicture,$aboutbuttonlabel,$settingspanel, $backuppanel, $restorepanel, $troubleshootingpanel, $toolboxpanel, $aboutpanel))
$mainwindow.Controls.AddRange(@($logo,$bottomwindow))

# Display the form
[void]$mainwindow.ShowDialog()
