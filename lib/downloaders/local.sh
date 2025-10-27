#!/bin/bash

downloader_info() {
  echo "type:local"
}

download() {
  local file_path="$1"
  local dest="$2"
  local version="$3"
  local type="$4"

  local final_file_path="$file_path"
  local final_dest="$dest"

  # If supplied file name / path contains version placeholders
  if has_version_placeholder "$file_path"; then
    final_file_path=$(substitute_version "$file_path" "$version")
  fi

  if [[ ! "$final_file_path" = /* ]]; then # If provided source path is relative
    final_file_path="$workdir/$final_file_path"
  fi

  if [[ -d "$dest" ]]; then # If the provided dest is a directory
    log info "Destination $dest is a directory, constructing full destination path..."
    final_dest="$dest/$(basename $file_path)"
  fi

  if [[ ! -f "$final_file_path" ]]; then
    log error "Supplied local file could not be found at $final_file_path"
    return 1
  fi

  log info "Copying: $final_file_path"
  log info "Destination: $final_dest"

  cp "$final_file_path" "$final_dest"

  if [[ ! -f "$final_dest" ]]; then
    log error "File not copied successfully to destination."
    return 1
  fi

  log info "Local file copied successfully"
  echo "DOWNLOADED_FILE=$final_dest"
  return 0
}
