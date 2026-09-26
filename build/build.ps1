param(
    [string]$ConfigurationName, 
    [string]$OutDir,
    [string]$SolutionDir,
    [string]$ToolboxPath
)

$PlaynitePaths = @(
    "C:\Playnite_dev", "C:\Projects\Playnite_dev",
    "D:\Playnite_dev", "D:\Projects\Playnite_dev",
    "G:\Playnite_dev", "G:\Projects\Playnite_dev",
    "F:\Playnite_dev", "F:\Projects\Playnite_dev"
)

$ResolvedToolboxPath = $ToolboxPath

if ([string]::IsNullOrWhiteSpace($ResolvedToolboxPath)) {
    foreach ($path in $PlaynitePaths) {
        if (Test-Path -Path $path) {
            $ResolvedToolboxPath = Join-Path $path "toolbox.exe"
            break
        }
    }
}

if ($null -eq $ResolvedToolboxPath -or -not (Test-Path -Path $ResolvedToolboxPath)) {
    Write-Host "No Playnite path valid found"
} 
else {
    $OutDirPath = (Join-Path $OutDir "..")

    if ($ConfigurationName -eq "debug-release") {
		if (Test-Path $ResolvedToolboxPath) {
			$string = & $ResolvedToolboxPath "pack" $OutDir $OutDirPath
            if ($LASTEXITCODE -ne 0) {
                throw "Playnite Toolbox failed to pack the extension."
            }
            Write-Host $string

            if ($string -match '"([^"]+)"') {
                $fullPath = $matches[1]
                $fileName = Split-Path -Path $fullPath -Leaf
                $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
                
                $zipPath = Join-Path $OutDirPath ($fileNameWithoutExt + ".zip")
                if (Test-Path $zipPath) {
                    Remove-Item $zipPath -Force
                }
                Compress-Archive -Path $fullPath -DestinationPath $zipPath
                Write-Host "Compressed as ""$zipPath"""
            }
		} 
		else {
			Write-Host "toolbox.exe not found."
		}		
	}

    if ($ConfigurationName -eq "release") {
        $Version = ""

        foreach ($Line in Get-Content (Join-Path $SolutionDir "extension.yaml")) {
            if ($Line -imatch "Version:") {
                $Version = $Line
            }
        }

        $Manifest = (Join-Path $SolutionDir "..\manifest\")
        $YmlFile = Get-ChildItem -Path $Manifest -Filter *.yaml | Select-Object -First 1
        $Manifest = (Join-Path $Manifest $YmlFile.Name)

        $Result = Get-Content $Manifest

        if ($Result -imatch $Version) {
            if (Test-Path $ResolvedToolboxPath) {
                & $ResolvedToolboxPath "pack" $OutDir $OutDirPath

                $Result = & $ResolvedToolboxPath "verify" "installer" $Manifest
                if ($Result -imatch "Installer manifest passed verification") {
                    # Si n�cessaire, ajouter des actions ici en cas de r�ussite
                } else {
                    Write-Host $Result
                }
            } 
			else {
                Write-Host "toolbox.exe not found."
            }
        } 
		else {
            Write-Host "Manifest does not contain the actual version"
        }
    }
}
