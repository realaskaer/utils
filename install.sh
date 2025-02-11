#!/usr/bin/env bash

function check_params() {
  if [[ -z "$1" ]]; then
    echo "Software name must be provided as a parameter"
    exit 1
  fi
}

function check_os() {
  KERNEL_NAME="$1"
  if [[ ! "$KERNEL_NAME" =~ ^(Linux|Darwin)$ ]]; then
    echo "$KERNEL_NAME is not supported"
    exit 1
  fi
}

function check_dir() {
  SOFTWARE_NAME="$1"
  if [[ -n "$(ls -A)" ]]; then
    echo "The directory is not empty. Found files:"
    ls -A
    echo "You need to install $SOFTWARE_NAME in an empty directory"
    exit 1
  fi
}

function check_git() {
  echo "Checking Git"
  if ! command -v git &> /dev/null; then
    echo "Git is not installed"
    return 1
  else
    echo "Git is already installed"
    return 0
  fi
}

function install_git() {
  echo "Starting to install git"
  if command -v brew &> /dev/null; then
    brew install git
  elif command -v apt &> /dev/null; then
    sudo apt update && sudo apt install -y git
  elif command -v yum &> /dev/null; then
    sudo yum install -y git
  elif command -v dnf &> /dev/null; then
    sudo dnf install -y git
  elif command -v zypper &> /dev/null; then
    sudo zypper install -y git
  else
    echo "Package manager could not be defined, you need to install git manually"
    exit 1
  fi
}

function check_jq() {
  echo "Checking jq"
  if ! command -v git &> /dev/null; then
    echo "jq is not installed"
    return 1
  else
    echo "jq is already installed"
    return 0
  fi
}

function install_jq() {
  echo "Starting to install jq"
  if command -v brew &> /dev/null; then
    brew install jq
  elif command -v apt &> /dev/null; then
    sudo apt update && sudo apt install -y jq
  elif command -v yum &> /dev/null; then
    sudo yum install -y jq
  elif command -v dnf &> /dev/null; then
    sudo dnf install -y jq
  elif command -v zypper &> /dev/null; then
    sudo zypper install -y jq
  else
    echo "Package manager could not be defined, you need to install jq manually"
    exit 1
  fi
}

function download_software() {
  SOFTWARE_NAME="$1"
  KERNEL_NAME="$2"

  echo "Starting to download $SOFTWARE_NAME"

  RELEASE_DATA=$(curl -fsSL https://api.github.com/repos/askaer-solutions/$SOFTWARE_NAME/releases/latest)

  if [[ "$(uname -s)" == "Darwin" ]]; then
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

  echo "Downloading $SOFTWARE_NAME from $DOWNLOAD_URL"
  curl -fsSL -o "$SOFTWARE_FILE" "$DOWNLOAD_URL" || { echo "Failed to download $SOFTWARE_NAME"; exit 1; }

  chmod +x "$SOFTWARE_FILE"
  echo "Installation has been successfully completed"
  echo "Starting $SOFTWARE_NAME"
  ./"$SOFTWARE_FILE"
}

function start() {
  check_params "$1"

  SOFTWARE_NAME="$1"
  KERNEL_NAME="$(uname -s)"

  check_os "$KERNEL_NAME"
  check_dir "$SOFTWARE_NAME"

  if ! check_git; then
    install_git || { echo "Failed to install git"; exit 1; }
  fi

  if ! check_jq; then
    install_jq || { echo "Failed to install jq"; exit 1; }
  fi

  download_software "$SOFTWARE_NAME" "$KERNEL_NAME"
}

start "$1"
