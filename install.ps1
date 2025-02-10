# powershell -ExecutionPolicy Bypass -NoProfile -Command "& {Invoke-Expression ([System.Text.Encoding]::UTF8.GetString((Invoke-WebRequest -Uri 'https://sdmeth.github.io/utils/install.ps1').Content))}"

Write-Host "Hello world!"