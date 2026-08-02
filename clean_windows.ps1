param(
     [switch]$Uncomment
 )

$ErrorActionPreference = 'Stop'

# Set-Content defaults to ANSI on Windows PowerShell 5.1, which would silently
# mangle any non-ASCII character in a file we touch. Always write UTF-8, no BOM.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Write-Lines([string]$Path, [string[]]$Lines) {
    [System.IO.File]::WriteAllLines($Path, $Lines, $utf8NoBom)
}

# Change to the directory where this script is located
Set-Location -Path $PSScriptRoot

$dartFiles = Get-ChildItem -Path . -Recurse -Filter '*.dart' -File

foreach ($file in $dartFiles) {
    $path = $file.FullName

    if (Select-String -Path $path -Pattern 'WINDOWS:REMOVE' -SimpleMatch -Quiet) {
        $content = Get-Content -LiteralPath $path

        $newContent = @()

        foreach ($line in $content) {
            if ($line -like '*WINDOWS:REMOVE*') {
                if ($Uncomment) {
                    # Uncomment: remove leading // from the line containing WINDOWS:REMOVE
                    $newContent += ($line -replace '^(\s*)//\s?', '$1')
                }
                else {
                    # Comment: add // at the start of the line if not already commented
                    if ($line -match '^(\s*)//') {
                        $newContent += $line
                    }
                    else {
                        $newContent += ($line -replace '^(\s*)', '$1// ')
                    }
                }
            }
            else {
                $newContent += $line
            }
        }

        Write-Lines $path $newContent
    }
}

# Also process pubspec.yaml: toggle comment on any line containing WINDOWS:REMOVE
$pubspecPath = Join-Path -Path $PSScriptRoot -ChildPath 'pubspec.yaml'
if (Test-Path -LiteralPath $pubspecPath) {
    $content = Get-Content -LiteralPath $pubspecPath

    $newContent = @()

    foreach ($line in $content) {
        if ($line -like '*WINDOWS:REMOVE*') {
            if ($Uncomment) {
                # Uncomment: remove leading # from the line containing WINDOWS:REMOVE
                $newContent += ($line -replace '^(\s*)#\s?', '$1')
            }
            else {
                # Comment: add # at the start of the line if not already commented
                if ($line -match '^(\s*)#') {
                    $newContent += $line
                }
                else {
                    $newContent += ($line -replace '^(\s*)', '$1# ')
                }
            }
        }
        else {
            $newContent += $line
        }
    }

    Write-Lines $pubspecPath $newContent
}