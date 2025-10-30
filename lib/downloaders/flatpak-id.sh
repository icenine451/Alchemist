#!/bin/bash

# Describe this downloader's capabilities
downloader_info() {
  echo "type:flatpak-id"
}

download() {
  local flatpak_id="$1"
  local flatpak_install_mode="$2"
  local flatpak_version="$3"
  local type="$4"
  local max_retries="${5:-3}"
  local initial_delay="${6:-2}"
  local max_delay="${7:-30}"

  if [[ "$flatpak_install_mode" == "user" ]]; then
    final_dest="$FLATPAK_USER_ROOT/app/$flatpak_id/current/$flatpak_version/files"
  elif [[ "$flatpak_install_mode" == "system" ]]; then
    final_dest="$FLATPAK_SYSTEM_ROOT/app/$flatpak_id/current/$flatpak_version/files"
  else
    log warn "Provided Flatpak destination invalid. Valid options are \"user\" or \"system\". Defaulting to \"$FLATPAK_DEFAULT_INSTALL_MODE\" install type."
    flatpak_install_mode="$FLATPAK_DEFAULT_INSTALL_MODE"
    final_dest="$FLATPAK_USER_ROOT/app/$flatpak_id/current/$flatpak_version/files"
  fi

  log info "Downloading: $final_flatpak_id"
  log info "Destination: $final_dest"
  log info "Flatpak Install Mode: $flatpak_install_mode"

  download_cmd() {
    install_flatpak "$flatpak_id" "$flatpak_version" "$flatpak_install_mode" "app" 2>&1
  }

  if ! try "$max_retries" "$initial_delay" "$max_delay" download_cmd; then
    log error "Download failed: $final_flatpak_id"
    return 1
  fi

  # Verify local Flatpak install exists
  if [[ ! -d "$final_dest" ]]; then
    log error "Flatpak not installed at desired destination: $final_dest"
    return 1
  fi

  log info "Flatpak install completed successfully"
  echo "DOWNLOADED_FILE=$final_dest"
  return 0
}
