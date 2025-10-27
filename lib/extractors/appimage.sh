#!/bin/bash

extractor_info() {
  echo "type:appimage"
}

extract() {
  local archive="$1"
  local dest="$2"
  local type="$3"

  if [[ ! -f "$archive" ]]; then
    log error "File $archive not found"
    return 1
  fi

  local final_dest="$dest/squashfs-root"

  extract_cmd() {
    chmod +x "$archive"
    cd "$dest" && "$archive" --appimage-extract
  }

  extract_cmd "$archive"

  if [[ ! -d "$final_dest" ]]; then
    log error "AppImage $archive could not be extracted"
    return 1
  fi

  # Clean up archive after extraction
  log info "Extraction successful, removing downloaded archive $archive"
  rm "$archive"

  log info "AppImage $archive was successfully extracted"
  echo "EXTRACTED_PATH=$final_dest"
  return 0
}
