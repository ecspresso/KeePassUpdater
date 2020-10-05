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