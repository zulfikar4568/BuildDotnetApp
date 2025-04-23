#Requires -Version 7.0

$ErrorActionPreference = "Stop"

# Get the version from the tag
$version = $env:TAG_NO_V
if (-not $version) {
    Write-Error "No version found in TAG_NO_V environment variable"
    exit 1
}

# Create output directory
$outputDir = ".\installer\output"
if (Test-Path $outputDir) {
    Remove-Item -Recurse -Force $outputDir
}
New-Item -ItemType Directory -Force -Path $outputDir

# Copy files to output directory
Copy-Item -Path ".\BuildDotnetApp\bin\x64\Release\*" -Destination $outputDir -Recurse
Copy-Item -Path ".\BuildDotnetApp.CLI\bin\x64\Release\*" -Destination $outputDir -Recurse

# Build the MSI
$wixPath = "C:\Program Files (x86)\WiX Toolset v3.11\bin"
$env:Path = "$wixPath;$env:Path"

# Generate WiX fragment
heat dir $outputDir -gg -g1 -sf -sreg -srd -dr INSTALLFOLDER -cg ApplicationFiles -var var.SourceDir -out ".\installer\fragment.wxs"

# Build the MSI
candle -nologo -arch x64 -dSourceDir="$outputDir" -dVersion="$version" ".\installer\product.wxs" ".\installer\fragment.wxs"
light -nologo -ext WixUIExtension -ext WixUtilExtension -out ".\installer\BuildDotnetApp-$version-x64.msi" ".\installer\product.wixobj" ".\installer\fragment.wixobj"

# Clean up
Remove-Item -Recurse -Force $outputDir
Remove-Item ".\installer\*.wixobj"
Remove-Item ".\installer\fragment.wxs" 