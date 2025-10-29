#!/bin/bash

set -euo pipefail

parse_assemble_args() {
  type=""
  source=""
  dest=""
  root=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--type)
        type="$2"
        shift 2
        ;;
      -s|--source)
        source="$2"
        shift 2
        ;;
      -d|--dest)
        dest="$2"
        shift 2
        ;;
      -r|--root)
        root="$2"
        shift 2
        ;;
      *)
        log error "Unknown option: $1"
        return 1
        ;;
    esac
  done

  # Validate required arguments
  if [[ ! -n "$type" || ! -n "$source" || ! -n "$dest" ]]; then
    log error "Missing required arguments"
    return 1
  fi

  if [[ ! -n "$root" ]]; then # If a root dir for the asset is not defined, assume the workdir
    root="$WORKDIR"
  fi
}

assemble() {
  local type="$1"
  local source="$2"
  local dest="$3"
  local root="$4"

  local final_source="$root/$source"
  local final_dest="$COMPONENT_ARTIFACT_ROOT/$dest"

  if [[ ! -e "$final_source" ]]; then
    log error "Provided source $final_source does not exist, cannot grab asset"
    return 1
  fi

  if [[ "$type" == "file" ]]; then
    final_dest="$final_dest/$(basename $source)"
  fi

  if [[ ! -d "$(dirname $final_dest)" ]]; then # If destination dir does not already exist
    log info "Destination dir $(dirname $final_dest) does not exist, creating"
    mkdir -p "$(dirname $final_dest)"
  fi

  case "$type" in
    dir)
      assemble_cmd() {
        cp -r "$1" "$2"
      }
      ;;
    file)
      assemble_cmd() {
        cp "$1" "$2"
      }
      ;;
    *)
      log error "Error: Unsupported asset type: $type"
      return 1
      ;;
  esac

  if ! assemble_cmd "$final_source" "$final_dest"; then
    log error "Asset $final_source could not be placed in $final_dest, exiting."
    return 1
  fi

  if [[ ! -e "$final_dest" ]]; then
    log error "Asset $final_dest could not be validated, exiting."
    return 1
  fi

  log info "Asset $final_source copied to $final_dest"
  return 0
}

process_assemble() {
  parse_assemble_args "$@"

  if ! assemble "$type" "$source" "$dest" "$root"; then
    log error "Assembling asset failed"
    return 1
  fi

  return 0
}
