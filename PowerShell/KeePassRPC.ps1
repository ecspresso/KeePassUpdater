function Format-KeePass {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeLine = $true)]
        [String]$update_information
    )

    # Save delimiter
    $delimiter = $update_information[0]

    # Split data on new line
    $split = $update_information.split([System.Environment]::NewLine)
    if($delimiter.length -gt 1) {
        $delimiter = $split[0][0]
    }

    $formated = @{}
    # Loop each line in data
    foreach($plugin in $split) {
        # Do not parse first and last line
        if(![bool]$plugin.StartsWith($delimiter)) {
            # Save plugin name and version
            $formated[$plugin.split($delimiter)[0]] = $plugin.split($delimiter)[1]
        }
    }

    return $formated
}


function Update-Plugin {
    param(
        [Parameter(Mandatory = $true)]
        [String]$update_uri,
        [Parameter(Mandatory = $true)]
        [String]$plugin_name,
        [Parameter(Mandatory = $true)]
        [String]$author,
        [Parameter(Mandatory = $true)]
        [String]$repo,
        [String]$reg_path = 'HKLM:\SOFTWARE\KeePassPluginUpdater',
        [String]$keepass_folder = "${env:ProgramFiles(x86)}\KeePass Password Safe 2"
    )

    # Get plugin version data
    $plugin_version_data = Invoke-RestMethod -Uri $update_uri | Format-KeePass

    # Test if registry key exists
    if(-not (Test-Path $reg_path)) {
        # Create key
        New-Item -Path $reg_path -ItemType Directory
    }

    # Test if registry value exists
    if(-not [bool](Get-ItemProperty -Path $reg_path -Name $plugin_name -ErrorAction SilentlyContinue)) {
        # Create value
        New-ItemProperty -Path $reg_path -Name $plugin_name -Value 0 -PropertyType 'String'
    }

    # Compare value to latest version
    if($plugin_version_data[$plugin_name] -ne (Get-ItemPropertyValue -Path $reg_path -Name $plugin_name)) {
        # Stop KeePass
        Start-Process -FilePath "$keepass_folder\KeePass.exe" -ArgumentList '--exit-all'
        # Get latest release from Github
        $release = Invoke-RestMethod "https://api.github.com/repos/$author/$repo/releases/latest"
        # Extract filename keep it the same
        $filename = $release.assets.browser_download_url -replace '.+\/(\w+\.plgx)', '$1'
        # Delete old file
        if(Test-Path "$keepass_folder\plugins\$filename") {
            Remove-Item -Path "$keepass_folder\plugins\$filename"
        }
        # Download plugin file and save it in keepass folder
        Invoke-WebRequest -Uri $release.assets.browser_download_url -OutFile "$keepass_folder\plugins\$filename"
        # Update value in registry
        Set-ItemProperty -Path $reg_path -Name $plugin_name -Value $plugin_version_data[$plugin_name]
        # Start KeePass again
        Start-Process -FilePath "$keepass_folder\KeePass.exe"
    }
}


$parameters = @{
    update_uri  = 'https://raw.githubusercontent.com/kee-org/keepassrpc/master/versionInfo.txt'
    plugin_name = 'KeePassRPC'
    author      = 'kee-org'
    repo        = 'keepassrpc'
}

Update-Plugin @parameters