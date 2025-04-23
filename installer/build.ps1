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
candle -nologo -arch x64 -dSourceDir="$outputDirMain" -dVersion="$version" ".\installer\product.wxs" ".\installer\fragment.main.wxs" -out ".\installer\main\"

Write-Host "Linking WiX files for main application..."
light -nologo -ext WixUIExtension -ext WixUtilExtension -out ".\installer\v$version-x64.msi" ".\installer\main\product.wixobj" ".\installer\main\fragment.main.wixobj" -b "$outputDirMain"

# Build CLI application installer
Write-Host "Building CLI application installer..."
Write-Host "Generating WiX fragment for CLI application..."
heat dir $outputDirCli -gg -g1 -sf -sreg -srd -dr INSTALLFOLDER -cg ApplicationFiles -var var.SourceDir -out ".\installer\fragment.cli.wxs"

Write-Host "Compiling WiX files for CLI application..."
candle -nologo -arch x64 -dSourceDir="$outputDirCli" -dVersion="$version" ".\installer\product.cli.wxs" ".\installer\fragment.cli.wxs" -out ".\installer\cli\"

Write-Host "Linking WiX files for CLI application..."
light -nologo -ext WixUIExtension -ext WixUtilExtension -out ".\installer\v$version-cli-x64.msi" ".\installer\cli\product.cli.wixobj" ".\installer\cli\fragment.cli.wixobj" -b "$outputDirCli"

# Sign the MSI files if certificate is available
if ($env:SIGN_CERTIFICATE_PATH -and $env:SIGN_CERTIFICATE_PASSWORD) {
    Write-Host "Signing MSI files..."
    
    # Import the certificate
    $cert = Import-PfxCertificate -FilePath $env:SIGN_CERTIFICATE_PATH -Password (ConvertTo-SecureString -String $env:SIGN_CERTIFICATE_PASSWORD -AsPlainText -Force)
    
    # Sign the main application MSI
    Write-Host "Signing main application MSI..."
    signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 /a /f $env:SIGN_CERTIFICATE_PATH /p $env:SIGN_CERTIFICATE_PASSWORD ".\installer\v$version-x64.msi"
    
    # Sign the CLI application MSI
    Write-Host "Signing CLI application MSI..."
    signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 /a /f $env:SIGN_CERTIFICATE_PATH /p $env:SIGN_CERTIFICATE_PASSWORD ".\installer\v$version-cli-x64.msi"
} else {
    Write-Host "Warning: No code signing certificate provided. MSI files will not be signed."
}

# Clean up
Write-Host "Cleaning up temporary files..."
Remove-Item -Recurse -Force ".\installer\output"
Remove-Item -Recurse -Force ".\installer\main"
Remove-Item -Recurse -Force ".\installer\cli"
Remove-Item ".\installer\fragment.*.wxs" 