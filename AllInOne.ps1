function Format-KeePass {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeLine = $true)]
        [String]$update_information
    )

    begin {
        $data = @()
    }

    process {
        $data += $update_information
    }

    end {
        # Save delimiter
        $delimiter = $data[0]

        # Split data on new line
        if($delimiter.length -gt 1) {
            $delimiter = $data[0][0]
        }

        $formated = @{}
        # Loop each line in data
        foreach($plugin in $data) {
            # Do not parse first and last line
            if(![bool]$plugin.StartsWith($delimiter)) {
                # Save plugin name and version
                $formated[$plugin.split($delimiter)[0]] = $plugin.split($delimiter)[1]
            }
        }

        return $formated
    }
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
    }
}

$keepass_folder = "${env:ProgramFiles(x86)}\KeePass Password Safe 2"

# Stop KeePass
Start-Process -FilePath "$keepass_folder\KeePass.exe" -ArgumentList '--exit-all'

$registry = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\KeePassPasswordSafe2_is1').DisplayVersion
$version = (Invoke-RestMethod -Uri 'https://www.dominik-reichl.de/update/version2x.txt.gz' | Format-KeePass)['KeePass']

if($registry -lt $version) {
    if(-not (Test-Path -Path 'C:\temp\')) {
        New-Item -Path 'C:\temp\' -ItemType 'Directory'
    }

    Invoke-WebRequest -Uri "https://sourceforge.net/projects/keepass/files/KeePass%202.x/$version/KeePass-$version-Setup.exe/download" -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox -OutFile "C:\temp\KeePass-$version.exe"
    Start-Process -FilePath "C:\temp\KeePass-$version.exe" -ArgumentList '/SILENT' -Wait
    Remove-Item -Path "C:\temp\KeePass-$version.exe"
}

$parameters = @{
    update_uri  = 'https://raw.githubusercontent.com/rookiestyle/keepassotp/master/version.info'
    plugin_name = 'KeePassOTP'
    author      = 'Rookiestyle'
    repo        = 'KeePassOTP'
}

Update-Plugin @parameters

$parameters = @{
    update_uri  = 'https://raw.githubusercontent.com/kee-org/keepassrpc/master/versionInfo.txt'
    plugin_name = 'KeePassRPC'
    author      = 'kee-org'
    repo        = 'keepassrpc'
}

Update-Plugin @parameters

$parameters = @{
    update_uri  = 'https://raw.githubusercontent.com/navossoc/KeePass-Yet-Another-Favicon-Downloader/master/VERSION'
    plugin_name = 'Yet Another Favicon Downloader'
    author      = 'navossoc'
    repo        = 'KeePass-Yet-Another-Favicon-Downloader'
}

Update-Plugin @parameters

# Start KeePass again
Start-Process -FilePath "$keepass_folder\KeePass.exe"