#!/bin/bash

extras_handler_info() {
  echo "type:symlink"
}

handle_extras() {
  local type="$1"
  local source="$2"
  local dest="$3"

  local final_source="$source"

  if [[ ! "$final_source" = /* ]]; then # If provided source path is relative
    final_source="$COMPONENT_ARTIFACT_ROOT/$final_source"
  fi

  log info "Creating symlink $final_source -> $dest"

  process_extras_cmd() {
    ln -s "$1" "$2"
  }

  if ! process_extras_cmd "$dest" "$final_source"; then
    log error "Symlink $final_source -> $dest could not be created"
    return 1
  fi

  if [[ ! -L "$final_source" ]]; then
    log error "Symlink $final_source -> $dest could not be validated"
    return 1
  fi

  log info "Symlink $final_source -> $dest created"
  return 0
}
