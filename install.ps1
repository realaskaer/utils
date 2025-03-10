param (
    [string]$SoftwareName
)

function Check-Params {
    param (
        [string]$SoftwareName
    )

    if (-not $SoftwareName) {
        Write-Host "Software name must be provided as a parameter"
        exit 1
    }
}

function Check-OS {
    if ($IsWindows -eq $false) {
        Write-Host "This script only supports Windows"
        exit 1
    }
}

function Check-Dir {
    param (
        [string]$SoftwareName
    )

    if ((Get-ChildItem -Path .).Count -gt 0) {
        Write-Host "The directory is not empty. Found files:"
        Get-ChildItem -Path .
        Write-Host "You need to install $SoftwareName in an empty directory"
        exit 1
    }
}

function Check-Node {
    Write-Host "Checking Node"
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host "Node is not installed"
        return $false
    }
    Write-Host "Node is already installed"
    return $true
}

function Install-Node {
    Write-Host "Installing Node"
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id OpenJS.NodeJS -e -h --accept-package-agreements 2> $null
    }
    else {
        choco install nodejs -y
    }
    Write-Host "Don't forget to restart the terminal for the changes to take effect"
}

function Download-Software {
    param (
        [string]$SoftwareName
    )

    Write-Host "Starting to download $SoftwareName"

    try {
        $Releases = Invoke-RestMethod -Uri "https://api.github.com/repos/askaer-solutions/$SoftwareName/releases" -UseBasicParsing

        $ValidRelease = $Releases | Where-Object { $_.assets | Where-Object { $_.name -match "windows.exe" } } | Select-Object -First 1

        if (-not $ValidRelease) {
            throw "No Windows version found in available releases"
        }

        $DownloadAsset = $ValidRelease.assets | Where-Object { $_.name -match "windows.exe" } | Select-Object -First 1
        $DownloadUrl = $DownloadAsset.browser_download_url

        if (-not $DownloadUrl) {
            throw "Failed to find a matching release for Windows"
        }

        $SoftwareFile = "$SoftwareName" + "_windows.exe"
        echo "Downloading $SoftwareName from $DownloadUrl"
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $SoftwareFile

        Write-Host "Installation has been successfully completed"
        Write-Host "Starting $SoftwareName"
        Start-Process -FilePath ".\$SoftwareFile" -NoNewWindow
    }
    catch {
        Write-Host "Failed to get latest release of $SoftwareName"
    }
}

function Start-Installation {
    param (
        [string]$SoftwareName
    )

    Check-Params -SoftwareName $SoftwareName
    Check-OS
    Check-Dir -SoftwareName $SoftwareName

    if (-not (Check-Node)) {
        Install-Node
    }

    Download-Software -SoftwareName $SoftwareName
}

Start-Installation -SoftwareName $SoftwareName