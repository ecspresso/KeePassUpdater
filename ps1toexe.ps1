$ps1 = Get-ChildItem -Path '.\PowerShell' -Filter "*.ps1"
$exe = Get-ChildItem -Path '.\exe'

foreach($file in $ps1) {
    if($exe.BaseName -notcontains $file.BaseName) {
        Invoke-ps2exe -inputFile $file.FullName -noConsole -noOutput -noVisualStyles -requireAdmin -outputFile "$($file.DirectoryName | Split-Path -Parent)\exe\$($file.BaseName).exe" -iconFile '.\icon.ico' -verbose
    }
}