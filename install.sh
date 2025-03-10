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

function check_jq() {
  echo "Checking jq"
  if ! command -v jq &> /dev/null; then
    echo "jq is not installed"
    return 1
  else
    echo "jq is already installed"
    return 0
  fi
}

function install_jq() {
  echo "Installing jq"
  if command -v brew &> /dev/null; then
    brew install -y jq
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

function check_node() {
  echo "Checking Node"
  if ! command -v node &> /dev/null; then
    echo "Node is not installed"
    return 1
  else
    echo "Node is already installed"
    return 0
  fi
}

function install_node() {
  echo "Installing Node"
  if command -v brew &> /dev/null; then
    brew install -y node
  elif command -v apt &> /dev/null; then
    sudo apt update && sudo apt install -y nodejs
  elif command -v yum &> /dev/null; then
    sudo yum install -y nodejs
  elif command -v dnf &> /dev/null; then
    sudo dnf install -y nodejs
  elif command -v zypper &> /dev/null; then
    sudo zypper install -y nodejs
  else
    echo "Package manager could not be defined, you need to install Node manually"
    exit 1
  fi
}

function download_software() {
  SOFTWARE_NAME="$1"
  KERNEL_NAME="$2"

  echo "Starting to download $SOFTWARE_NAME"

  RELEASES=$(curl -fsSL "https://api.github.com/repos/askaer-solutions/$SOFTWARE_NAME/releases")

  if [[ "$KERNEL_NAME" == "Darwin" ]]; then
    PLATFORM="macOS"
  else
    PLATFORM="linux"
  fi

  DOWNLOAD_URL=""
  SOFTWARE_FILE=""
  for row in $(echo "$RELEASES" | jq -r '.[] | @base64'); do
    RELEASE=$(echo "$row" | base64 --decode)
    DOWNLOAD_URL=$(echo "$RELEASE" | jq -r --arg PLATFORM "$PLATFORM" '.assets[]? | select(.name | test($PLATFORM)) | .browser_download_url')
    TAG_NAME=$(echo "$RELEASE" | jq -r '.tag_name')
    if [[ -n "$DOWNLOAD_URL" ]]; then
      SOFTWARE_FILE="${SOFTWARE_NAME}_${PLATFORM}"
      break
    fi
  done

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

  if ! check_jq; then
    install_jq || { echo "Failed to install jq"; exit 1; }
  fi

  if ! check_node; then
    install_node || { echo "Failed to install Node"; exit 1; }
    echo "Don't forget to restart the terminal for the changes to take effect"
  fi

  download_software "$SOFTWARE_NAME" "$KERNEL_NAME"
}

start "$1"
