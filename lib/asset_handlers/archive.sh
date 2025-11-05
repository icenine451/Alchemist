#!/bin/bash

asset_handler_info() {
  echo "type:archive"
}

handle_asset() {
  local type="$1"
  local source="$2"
  local dest="$3"

  local final_dest="$dest"

  if [[ ! "$final_dest" = /* ]]; then # If provided dest path is relative
    final_dest="$COMPONENT_ARTIFACT_ROOT/$dest"
  fi

  log info "Creating archive file $final_dest"

  process_asset_cmd() {
    tar -czf "$artifact_tar_file" -C "$COMPONENT_ARTIFACT_ROOT" .
  }

  if ! process_asset_cmd "$final_dest" "$contents"; then
    log error "File $final_dest could not be created"
    return 1
  fi

  log info "File $final_dest created"
  return 0
}
