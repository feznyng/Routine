param(
     [switch]$Uncomment
 )

$ErrorActionPreference = 'Stop'

# Change to the directory where this script is located
Set-Location -Path $PSScriptRoot

$dartFiles = Get-ChildItem -Path . -Recurse -Filter '*.dart' -File

foreach ($file in $dartFiles) {
    $path = $file.FullName

    if (Select-String -Path $path -Pattern 'WINDOWS:REMOVE' -SimpleMatch -Quiet) {
        $content = Get-Content -LiteralPath $path

        if (-not $Uncomment) {
            $newContent = @()

            foreach ($line in $content) {
                if ($line -like '*WINDOWS:REMOVE*') { 
                    $newContent += '//'
                }
                $newContent += $line
            }

            Set-Content -LiteralPath $path -Value $newContent -NoNewline:$false
        }
        else {
            $newContent = @()

            for ($i = 0; $i -lt $content.Length; $i++) {
                $line = $content[$i]

                if ($line -eq '//' -and $i + 1 -lt $content.Length -and $content[$i + 1] -like '*WINDOWS:REMOVE*') {
                    continue
                }

                $newContent += $line
            }

            Set-Content -LiteralPath $path -Value $newContent -NoNewline:$false
        }
    }
}

# Also process pubspec.yaml: remove any line containing WINDOWS:REMOVE
$pubspecPath = Join-Path -Path $PSScriptRoot -ChildPath 'pubspec.yaml'
if (Test-Path -LiteralPath $pubspecPath) {
    $content = Get-Content -LiteralPath $pubspecPath

    if (-not $Uncomment) {
        $newContent = @()

        foreach ($line in $content) {
            if ($line -like '*WINDOWS:REMOVE*') { 
                $newContent += '#'
            }
            $newContent += $line
        }

        Set-Content -LiteralPath $pubspecPath -Value $newContent -NoNewline:$false
    }
    else {
        $newContent = @()

        for ($i = 0; $i -lt $content.Length; $i++) {
            $line = $content[$i]

            if ($line -eq '#' -and $i + 1 -lt $content.Length -and $content[$i + 1] -like '*WINDOWS:REMOVE*') {
                continue
            }

            $newContent += $line
        }

        Set-Content -LiteralPath $pubspecPath -Value $newContent -NoNewline:$false
    }
}