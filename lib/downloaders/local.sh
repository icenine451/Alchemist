#!/bin/bash

downloader_info() {
  echo "type:local"
}

download() {
  local source="$1"
  local dest="$2"
  local version="$3"

  local final_source="$source"
  local final_dest="$dest"

  if [[ ! -d "$dest" ]]; then
    log error "Dest directory $dest does not exist, exiting..."
    return 1
  fi

  # If supplied file name / path contains version placeholders
  if has_version_placeholder "$source"; then
    final_source=$(substitute_version "$source" "$version")
  fi

  if [[ ! "$final_source" = /* ]]; then # If provided source path is relative
    final_source="$WORKDIR/$final_source"
  fi

  if [[ -d "$dest" ]]; then # If the provided dest is a directory
    log info "Destination $dest is a directory, constructing full destination path..."
    final_dest="$dest/$(basename $final_source)"
  fi

  if [[ ! -f "$final_source" ]]; then
    log error "Supplied local file could not be found at $final_source"
    return 1
  fi

  final_dest="$final_source"

  log info "Local file $final_dest validated, proceeding to extraction"
  echo "DOWNLOADED_FILE=$final_dest"
  return 0
}
