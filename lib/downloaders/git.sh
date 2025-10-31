#!/bin/bash

downloader_info() {
  echo "type:git"
}

download() {
  local url="$1"
  local dest="$2"
  local version="$3"
  local type="$4"
  local max_retries="${5:-3}"
  local initial_delay="${6:-2}"
  local max_delay="${7:-30}"

  local final_dest="$dest"

  if [[ ! "$final_dest" = /* ]]; then # If provided source path is relative
    final_dest="$WORKDIR/$final_dest"
  fi

  if [[ ! -d "$final_dest" ]]; then
    log info "Dest directory $final_dest does not exist, creating..."
    mkdir -p "$final_dest"
  fi

  log info "Cloning repository: $url"
  log info "Destination: $final_dest"

  download_cmd() {
    git clone --depth 1 "$1" "$2"
    if [[ -n "$3" && ! "$3" == "latest" ]]; then
      cd $(basename "$2")
      git fetch --depth 1 origin "$3"
      git checkout "$3"
    fi
  }

  if ! try "$max_retries" "$initial_delay" "$max_delay" download_cmd "$url" "$final_dest" "$version"; then
    log error "Git clone failed: $base_url"
    return 1
  fi

  # Verify clone succeeded
  if [[ ! -d "$final_dest/.git" ]]; then
    log error "Git clone verification failed: $final_dest"
    return 1
  fi

  log info "Clone completed successfully"
  echo "DOWNLOADED_FILE=$final_dest"
  return 0
}
