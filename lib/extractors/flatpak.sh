#!/bin/bash

extractor_info() {
  echo "type:flatpak"
}

extract() {
  local flatpak_source="$1"
  local dest="$2"
  local type="$3"

  log info "Flatpak $flatpak_source needs no extraction, proceeding to file gathering"
  echo "EXTRACTED_PATH=$flatpak_source"
  return 0
}
