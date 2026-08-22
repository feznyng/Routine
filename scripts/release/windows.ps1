# Build the Windows app and wrap it in an Inno Setup installer.
#
#   $env:VERSION_NAME / $env:BUILD_NUMBER   optional; default from pubspec.yaml
#   $env:SKIP_BUILD = '1'                   package an existing build/ tree only
#
#   just dist windows
#   powershell -ExecutionPolicy Bypass -File scripts/release/windows.ps1

$ErrorActionPreference = 'Stop'
Set-Location -Path (Join-Path $PSScriptRoot '..\..')

$version = $env:VERSION_NAME
$build   = $env:BUILD_NUMBER
if (-not $version -or -not $build) {
    $pubspec = (Select-String -Path pubspec.yaml -Pattern '^version:').Line -replace 'version:\s*', ''
    if (-not $version) { $version = ($pubspec -split '\+')[0] }
    if (-not $build)   { $build   = ($pubspec -split '\+')[1] }
}
Write-Host "==> Releasing $version (build $build)"

if (-not $env:SKIP_BUILD) {
    # Must go through `just`, not `flutter build` directly:
    #   - build-nmh windows produces assets/extension/native_windows.exe, which
    #     windows/CMakeLists.txt install()s into the bundle. Its absence is only
    #     a CMake *warning*, so a direct build goes green with blocking dead.
    #   - firebase-strip/restore works around firebase_core being unbuildable on
    #     Windows (its CMake step downloads the C++ SDK).
    Write-Host '==> Building (via just: NMH + firebase-strip)'
    just release windows --build-name=$version --build-number=$build
}

if (-not (Test-Path 'build\windows\x64\runner\Release')) {
    throw 'No Windows build output'
}

# --- Code signing goes here, once the LLC clears Azure Artifact Signing's
# --- ~3-year organization validation bar. Sign the .exe and .dll files BEFORE
# --- packaging, then sign the installer produced below.

$iscc = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $iscc) {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host '==> Installing Inno Setup'
        choco install innosetup -y --no-progress
        $iscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
    } else {
        throw 'Inno Setup not found and choco unavailable'
    }
}

New-Item -ItemType Directory -Force -Path dist | Out-Null
Write-Host '==> Packaging installer'
& $iscc "/DAppVersion=$version" 'windows\packaging\routine.iss'

Write-Host "==> dist\Routine-$version-setup.exe"
