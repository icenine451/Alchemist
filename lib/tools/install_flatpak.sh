#!/bin/bash

install_flatpak() {
  local flatpak_id="$1"
  local flatpak_version="$2"
  local flatpak_install_mode="$3"

  local final_flatpak_id="$flatpak_id"

  if ! flatpak remote-add --if-not-exists flathub "$FLATHUB_REPO"; then # Ensure flathub is added as a remote
    log error "FlatHub could not be added as a remote"
    return 1
  fi

  if ! flatpak install --"$dest" -y --or-update --noninteractive flathub "$final_flatpak_id" 2>&1; then
    log error "Flatpak $flatpak_id could not be installed."
    return 1
  fi

  return 0
}
