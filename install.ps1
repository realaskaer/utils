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

function Download-Software {
    param (
        [string]$SoftwareName
    )

    Write-Host "Downloading $SoftwareName"

    try {
        $ReleaseData = Invoke-RestMethod -Uri "https://api.github.com/repos/askaer-solutions/$SoftwareName/releases/latest" -UseBasicParsing
        $DownloadUrl = $ReleaseData.assets | Where-Object { $_.name -match "windows" } | Select-Object -ExpandProperty browser_download_url

        $SoftwareFile = "$SoftwareName" + "_windows.exe"
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $SoftwareFile -ProgressAction 'Continue'

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

    Download-Software -SoftwareName $SoftwareName
}

Start-Installation -SoftwareName $SoftwareName