#!/bin/bash

extras_handler_info() {
  echo "type:dir,file"
}

handle_extras() {
  local type="$1"
  local source="$2"
  local dest="$3"

  local final_source="$source"
  local final_dest="$dest"

  if [[ ! "$final_source" = /* ]]; then # If provided source path is relative
    final_source="$WORKDIR/$source"
  fi

  if [[ ! "$final_dest" = /* ]]; then # If provided dest path is relative
    final_dest="$COMPONENT_ARTIFACT_ROOT/$final_dest"
  fi

  case "$type" in
    file)
      process_extras_cmd() {
        if [[ ! -d $(dirname "$2") ]]; then
          mkdir -p $(dirname "$2")
        fi
        cp "$1" "$2"
      }
    ;;
    dir)
      process_extras_cmd() {
        if [[ ! -d "$2" ]]; then
          mkdir -p "$2"
        fi
        cp -r "$1/"* "$2"
      }
    ;;
    *)
      log error "Error: Unsupported type: $type"
      return 1
    ;;
  esac

  log info "Copying source: $final_url"
  log info "Copying destination: $final_dest"

  if ! process_extras_cmd "$final_source" "$final_dest"; then
    log error "Extra source \"$final_source\" could not be processed to dest \"$final_dest\""
    return 1
  fi

  log info "Extra source \"$final_source\" processed to dest \"$final_dest\""
  return 0
}
