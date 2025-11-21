param()

$ErrorActionPreference = 'Stop'

# Change to the directory where this script is located
Set-Location -Path $PSScriptRoot

if (-not (git rev-parse --is-inside-work-tree 2>$null)) {
    Write-Error "build_windows.ps1 must be run inside a git repository"
    exit 1
}

git stash | Out-Null
git stash -u | Out-Null

try {
    $dartFiles = Get-ChildItem -Path . -Recurse -Filter '*.dart' -File

    foreach ($file in $dartFiles) {
        $path = $file.FullName

        if (Select-String -Path $path -Pattern 'MARK:REMOVE' -SimpleMatch -Quiet) {
            $content = Get-Content -LiteralPath $path

            $newContent = @()

            foreach ($line in $content) {
                if ($line -like '*MARK:REMOVE*') { continue }
                $newContent += $line
            }

            Set-Content -LiteralPath $path -Value $newContent -NoNewline:$false
        }
    }
    
    # Also process pubspec.yaml: remove any line containing MARK:REMOVE
    $pubspecPath = Join-Path -Path $PSScriptRoot -ChildPath 'pubspec.yaml'
    if (Test-Path -LiteralPath $pubspecPath) {
        $content = Get-Content -LiteralPath $pubspecPath

        $newContent = @()

        foreach ($line in $content) {
            if ($line -like '*MARK:REMOVE*') { continue }
            $newContent += $line
        }

        Set-Content -LiteralPath $pubspecPath -Value $newContent -NoNewline:$false
    }

    flutter build windows --release
}
finally {
    try { git reset --hard | Out-Null } catch {}
    try { git stash pop | Out-Null } catch {}
    try { git stash pop | Out-Null } catch {}
}
