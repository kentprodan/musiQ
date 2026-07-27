#Requires -Version 5.1
<#
  Regenerates the C# UniFFI bindings for musiq-uniffi and copies the native
  cdylib + generated bindings into the WinUI3 project. Run manually, or via
  the MusiqWindows.csproj BeforeBuild target.

  Prerequisite (installed once): cargo install uniffi-bindgen-cs --git
  https://github.com/NordSecurity/uniffi-bindgen-cs --tag v0.11.0+v0.31.0
#>
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$bindingsOut = Join-Path $repoRoot "bindings\csharp"
$winuiProject = Join-Path $repoRoot "clients\windows-winui\MusiqWindows"
$generatedDir = Join-Path $winuiProject "Generated"
$nativeDir = Join-Path $winuiProject "runtimes\win-x64\native"

Write-Host "==> Building musiq-uniffi (release)"
Push-Location $repoRoot
try {
    cargo build -p musiq-uniffi --release
    if ($LASTEXITCODE -ne 0) { throw "cargo build failed" }
}
finally {
    Pop-Location
}

$dllPath = Join-Path $repoRoot "target\release\musiq_uniffi.dll"
if (-not (Test-Path $dllPath)) {
    throw "Expected cdylib not found at $dllPath"
}

Write-Host "==> Generating C# bindings"
New-Item -ItemType Directory -Force -Path $bindingsOut | Out-Null
uniffi-bindgen-cs --library $dllPath --out-dir $bindingsOut --no-format
if ($LASTEXITCODE -ne 0) { throw "uniffi-bindgen-cs failed" }

Write-Host "==> Copying generated bindings + native dll into MusiqWindows"
New-Item -ItemType Directory -Force -Path $generatedDir | Out-Null
New-Item -ItemType Directory -Force -Path $nativeDir | Out-Null
Copy-Item -Force (Join-Path $bindingsOut "musiq_uniffi.cs") (Join-Path $generatedDir "musiq_uniffi.cs")
Copy-Item -Force $dllPath (Join-Path $nativeDir "musiq_uniffi.dll")

Write-Host "==> Done. Generated:"
Write-Host "    $generatedDir\musiq_uniffi.cs"
Write-Host "    $nativeDir\musiq_uniffi.dll"
