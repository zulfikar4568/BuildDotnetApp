#Requires -Version 7.0

$ErrorActionPreference = "Stop"

# Get the version from the tag
$version = $env:TAG_NO_V
if (-not $version) {
    Write-Error "No version found in TAG_NO_V environment variable"
    exit 1
}

# Create output directories
$outputDirMain = ".\installer\output\main"
$outputDirCli = ".\installer\output\cli"
if (Test-Path ".\installer\output") {
    Remove-Item -Recurse -Force ".\installer\output"
}
New-Item -ItemType Directory -Force -Path $outputDirMain
New-Item -ItemType Directory -Force -Path $outputDirCli

# Copy files to output directories
Write-Host "Copying application files..."
Copy-Item -Path ".\BuildDotnetApp\bin\x64\Release\*" -Destination $outputDirMain -Recurse
Copy-Item -Path ".\BuildDotnetApp.CLI\bin\x64\Release\*" -Destination $outputDirCli -Recurse

# Build the MSI
$wixPath = "C:\wix"
$env:Path = "$wixPath;$env:Path"

# Build main application installer
Write-Host "Building main application installer..."
Write-Host "Generating WiX fragment for main application..."
heat dir $outputDirMain -gg -g1 -sf -sreg -srd -dr INSTALLFOLDER -cg ApplicationFiles -var var.SourceDir -out ".\installer\fragment.main.wxs"

Write-Host "Compiling WiX files for main application..."
candle -nologo -arch x64 -dSourceDir="$outputDirMain" -dVersion="$version" ".\installer\product.wxs" ".\installer\fragment.main.wxs" -out ".\installer\"

Write-Host "Linking WiX files for main application..."
light -nologo -ext WixUIExtension -ext WixUtilExtension -out ".\installer\BuildDotnetApp-$version-x64.msi" ".\installer\product.wixobj" ".\installer\fragment.main.wixobj" -b "$outputDirMain"

# Build CLI application installer
Write-Host "Building CLI application installer..."
Write-Host "Generating WiX fragment for CLI application..."
heat dir $outputDirCli -gg -g1 -sf -sreg -srd -dr INSTALLFOLDER -cg ApplicationFiles -var var.SourceDir -out ".\installer\fragment.cli.wxs"

Write-Host "Compiling WiX files for CLI application..."
candle -nologo -arch x64 -dSourceDir="$outputDirCli" -dVersion="$version" ".\installer\product.cli.wxs" ".\installer\fragment.cli.wxs" -out ".\installer\"

Write-Host "Linking WiX files for CLI application..."
light -nologo -ext WixUIExtension -ext WixUtilExtension -out ".\installer\BuildDotnetApp.CLI-$version-x64.msi" ".\installer\product.cli.wixobj" ".\installer\fragment.cli.wixobj" -b "$outputDirCli"

# Clean up
Write-Host "Cleaning up temporary files..."
Remove-Item -Recurse -Force ".\installer\output"
Remove-Item ".\installer\*.wixobj"
Remove-Item ".\installer\fragment.*.wxs" 