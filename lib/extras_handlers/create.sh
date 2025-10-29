#!/bin/bash

extras_handler_info() {
  echo "type:create"
}

handle_extras() {
  local type="$1"
  local source="$2"
  local dest="$3"
  local location="$4"

  local final_dest="$dest"

  if [[ ! "$final_dest" = /* ]]; then # If provided dest path is relative
    final_dest="$COMPONENT_ARTIFACT_ROOT/$final_dest"
  fi

  log info "Creating file $final_dest"

  process_extras_cmd() {
    touch "$1"
  }

  if ! process_extras_cmd "$final_dest"; then
    log error "File $final_dest could not be created"
    return 1
  fi

  log info "File $final_dest created"
  return 0
}
