#!/bin/bash

set -euo pipefail

# Associative arrays for extras handler registry
declare -A EXTRAS_HANDLER_TYPES
declare -A EXTRAS_HANDLER_FILES

# Load all extras handler plugins
load_extras_handlers() {
  local extras_handler_dir="$SCRIPT_DIR/lib/extras_handlers"

  if [[ ! -d "$extras_handler_dir" ]]; then
    log error "Extras handler directory not found: $extras_handler_dir"
    return 1
  fi

  for extras_handler_file in "$extras_handler_dir"/*.sh; do
    if [[ ! -f "$extras_handler_file" ]]; then
      continue
    fi

    local filename
    filename=$(basename "$extras_handler_file")

    # Source the extras handler
    source "$extras_handler_file"

    # Check if extras_handler_info function exists
    if ! declare -f extras_handler_info > /dev/null; then
      log w "Extras handler $filename does not implement extras_handler_info()"
      continue
    fi

    # Parse extras handler info
    local info
    info=$(extras_handler_info)

    local types
    types=$(echo "$info" | grep "^type:" | cut -d: -f2)

    if [[ ! -n "$types" ]]; then
      log error "Extras handler $filename does not specify any types"
      continue
    fi

    # Register each type this extras handler handles
    IFS=',' read -ra TYPE_ARRAY <<< "$types"
    for type in "${TYPE_ARRAY[@]}"; do
      type=$(echo "$type" | xargs)  # Trim whitespace
      EXTRAS_HANDLER_TYPES["$type"]="$filename"
      EXTRAS_HANDLER_FILES["$filename"]="$extras_handler_file"
    done

    log info "Loaded extras handler: $filename (types: $types)"
  done
}

parse_handle_extras_args() {
  type=""
  source=""
  dest=""
  location=""

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
      -l|--location)
        location="$2"
        shift 2
        ;;
      *)
        log error "Unknown option: $1"
        return 1
        ;;
    esac
  done

  # Validate required arguments
  if [[ ! -n "$type" || ( ! -n "$source" && ! -n "$dest" ) ]]; then
    log error "Missing required arguments"
    return 1
  fi
}

process_handle_extras() {
  load_extras_handlers

  parse_handle_extras_args "$@"

  # Find appropriate extras handler for the specified type
  if [[ ! -n "${EXTRAS_HANDLER_TYPES[$type]:-}" ]]; then
    log error "No extras handler found for type: $type"
    return 1
  fi

  local extras_handler_file="${EXTRAS_HANDLER_TYPES[$type]}"
  source "$SCRIPT_DIR/lib/extras_handlers/$extras_handler_file"
  log info "Using extras handler: $extras_handler_file"

  if ! handle_extras "$type" "$source" "$dest" "$location"; then
    log error "Gathering extra files failed"
    return 1
  fi

  return 0
}
