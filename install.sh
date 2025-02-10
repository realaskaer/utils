#!/usr/bin/env bash

function check_params() {
  if [[ -z "$1" ]]; then
    echo "Software name must be provided as a parameter"
    exit 1
  fi
}

function check_os() {
  KERNEL_NAME="$(uname -s)"
  if [[ "$KERNEL_NAME" != "Linux" && "$KERNEL_NAME" != "Darwin" ]]; then
    echo "$KERNEL_NAME is not supported"
    exit 1
  fi
}

function check_dir() {
  if [[ -n "$(ls -A)" ]]; then
    echo "You need to install the software in an empty directory"
    exit 1
  fi
}

function check_git() {
  echo "Checking Git..."
  if ! command -v git &> /dev/null; then
    echo "Git is not installed"
    return 1
  else
    echo "Git is already installed"
    return 0
  fi
}

function install_git() {
  echo "Starting to install git..."
  if command -v brew &> /dev/null; then
    brew install git jq
  elif command -v apt &> /dev/null; then
    sudo apt update && sudo apt install -y git jq
  elif command -v yum &> /dev/null; then
    sudo yum install -y git jq
  elif command -v dnf &> /dev/null; then
    sudo dnf install -y git jq
  elif command -v zypper &> /dev/null; then
    sudo zypper install -y git jq
  else
    echo "Package manager could not be defined, you need to install git manually"
    exit 1
  fi
}

function install_software() {
  SOFTWARE_NAME="$1"
  KERNEL_NAME="$2"

  echo "Starting to install $SOFTWARE_NAME..."

  RELEASE_DATA=$(curl -fsSL https://api.github.com/repos/askaer-solutions/$SOFTWARE_NAME/releases/latest)

  if [[ "$KERNEL_NAME" == "Darwin" ]]; then
    DOWNLOAD_URL=$(echo "$RELEASE_DATA" | jq -r '.assets[] | select(.name | test("macOS")) | .browser_download_url')
    SOFTWARE_FILE="${SOFTWARE_NAME}_macOS"
  else
    DOWNLOAD_URL=$(echo "$RELEASE_DATA" | jq -r '.assets[] | select(.name | test("linux")) | .browser_download_url')
    SOFTWARE_FILE="${SOFTWARE_NAME}_linux"
  fi

  if [[ -z "$DOWNLOAD_URL" ]]; then
    echo "Failed to get latest release of $SOFTWARE_NAME"
    exit 1
  fi

  echo "Downloading $SOFTWARE_NAME from $DOWNLOAD_URL..."
  curl -fsSL -o "$SOFTWARE_FILE" "$DOWNLOAD_URL"

  if [[ $? -ne 0 ]]; then
    echo "Failed to download $SOFTWARE_NAME"
    exit 1
  fi

  chmod +x "$SOFTWARE_FILE"

  echo "Installation has been successfully completed. You can now run the software by executing: ./$SOFTWARE_FILE"
}

function start() {
  check_params "$1"

  SOFTWARE_NAME="$1"

  check_os
  check_dir

  if ! check_git; then
    install_git
  fi

  install_software "$SOFTWARE_NAME" "$(uname -s)"
}

start "$1"
