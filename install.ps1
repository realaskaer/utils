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

function Check-Git {
    Write-Host "Checking Git"
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Git is not installed"
        return $false
    }
    Write-Host "Git is already installed"
    return $true
}

function Install-Git {
    Write-Host "Installing Git"
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id Git.Git -e -h 2> $null
    }
    else {
        choco install git -y
    }
}

function Configure-Git {
    Write-Host "Configuring Git"
    git config --global user.email "email@astrum.com"
    git config --global user.name "user"
    Write-Host "Git configured"
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

    if (-not (Check-Git)) {
        Install-Git
    }

    Configure-Git

    Download-Software -SoftwareName $SoftwareName
}

Start-Installation -SoftwareName $SoftwareName