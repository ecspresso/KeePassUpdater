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

$registry = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\KeePassPasswordSafe2_is1').DisplayVersion
$gz = "version2x.txt.gz"
$txt = $gz.Replace(".gz","")
Invoke-RestMethod -Uri 'https://www.dominik-reichl.de/update/version2x.txt.gz' -OutFile $gz
nanazipc e $gz -y > $null 2>1
Remove-Item $gz
$version = (Get-Content $txt | Format-KeePass)['KeePass']
Remove-Item $txt

if($registry -lt $version) {
    if(-not (Test-Path -Path 'C:\temp\')) {
        New-Item -Path 'C:\temp\' -ItemType 'Directory'
    }

    Invoke-WebRequest -Uri "https://sourceforge.net/projects/keepass/files/KeePass%202.x/$version/KeePass-$version-Setup.exe/download" -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox -OutFile "C:\temp\KeePass-$version.exe"
    Start-Process -FilePath "C:\temp\KeePass-$version.exe" -ArgumentList '/SILENT' -Wait
    Remove-Item -Path "C:\temp\KeePass-$version.exe"
}