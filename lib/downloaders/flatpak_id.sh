#!/bin/bash

# Describe this downloader's capabilities
downloader_info() {
  echo "type:flatpak_id"
}

download() {
  local flatpak_id="$1"
  local dest="$2"
  local version="$3"
  local type="$4"
  local max_retries="${5:-3}"
  local initial_delay="${6:-2}"
  local max_delay="${7:-30}"

  local final_flatpak_id="$flatpak_id"
  local flatpak_install_mode="user"

  # Ensure flathub is added as a remote
  if ! flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
    echo "FlatHub could not be added as a remote"
    return 1
  fi

  if [[ "$dest" == "user" ]]; then
    final_dest="$FLATPAK_USER_ROOT"
  elif [[ "$dest" == "system" ]]; then
    final_dest="$FLATPAK_SYSTEM_ROOT"
    flatpak_install_mode="system"
  else
    echo "Provided Flatpak destination invalid. Valid options are \"user\" or \"system\""
    return 1
  fi

  if [[ ! "$version" == "latest" ]]; then # If a specific version was given, add it to the Flatpak ID
    final_flatpak_id="$flatpak_id//$version"
  fi

  echo "Downloading: $final_flatpak_id"
  echo "Destination: $final_dest"

  download_cmd() {
    flatpak install --"$flatpak_install_mode" -y --or-update --noninteractive flathub "$final_flatpak_id" 2>&1
  }

  if ! try "$max_retries" "$initial_delay" "$max_delay" download_cmd; then
    echo "Download failed: $final_flatpak_id"
    return 1
  fi

  # Verify local Flatpak install exists
  if [[ ! -d "$final_dest" ]]; then
    echo "Flatpak not installed at desired destination: $final_dest"
    return 1
  fi

  echo "Flatpak install completed successfully"
  return 0
}
