param()

$ErrorActionPreference = 'Stop'

# Change to the directory where this script is located
Set-Location -Path $PSScriptRoot

# Get all Dart files under this directory
$dartFiles = Get-ChildItem -Path . -Recurse -Filter '*.dart' -File

foreach ($file in $dartFiles) {
    $path = $file.FullName

    # Check if the file contains MARK:REMOVE
    if (Select-String -Path $path -Pattern 'MARK:REMOVE' -SimpleMatch -Quiet) {
        $content = Get-Content -LiteralPath $path

        $newContent = @()
        for ($i = 0; $i -lt $content.Length; $i++) {
            $line = $content[$i]
            $newContent += $line
            if ($line -like '*MARK:REMOVE*') {
                break
            }
        }

        Set-Content -LiteralPath $path -Value $newContent -NoNewline:$false
    }
}

# Build Windows release
flutter build windows --release
