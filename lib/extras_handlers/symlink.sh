#!/bin/bash

extras_handler_info() {
  echo "type:symlink"
}

handle_extras() {
  local type="$1"
  local source="$2"
  local dest="$3"
  local location="$4"

  log info "Creating symlink $dest -> $source at location $location"

  process_extras_cmd() {
    cd "$3" && ln -s "$1" "$2"
  }

  if ! process_extras_cmd "$dest" "$source" "$location"; then
    log error "Symlink $dest -> $source at location $location could not be created"
    return 1
  fi

  log info "Symlink $dest -> $source at location $location created"
  return 0
}
