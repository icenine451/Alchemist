#!/bin/bash

extractor_info() {
  echo "type:archive"
}

extract() {
  local archive="$1"
  local dest="$2"
  local type="$3"

  local final_dest="$dest/$(basename $archive)-extracted"

  local file_ext="$(basename $archive)"
  file_ext="${file_ext##*.}"

  case "$file_ext" in
    7z)
      extract_cmd() {
        7z x "$1" -o"$2"
      }
      ;;
    zip)
      extract_cmd() {
        unzip -q "$1" -d "$2"
      }
      ;;
    tar.gz|tgz)
      extract_cmd() {
        mkdir -p "$2"
        tar -xzf "$1" -C "$2"
      }
      ;;
    tar.bz2|tbz2)
      extract_cmd() {
        mkdir -p "$2"
        tar -xjf "$1" -C "$2"
      }
      ;;
    tar.xz|txz)
      extract_cmd() {
        mkdir -p "$2"
        tar -xJf "$1" -C "$2"
      }
      ;;
    tar)
      extract_cmd() {
        mkdir -p "$2"
        tar -xf "$1" -C "$2"
      }
      ;;
    *)
      log error "Error: Unsupported archive type: $type"
      return 1
      ;;
  esac

  if ! extract_cmd "$archive" "$final_dest"; then
    log error "Extraction of archive $archive could not be completed"
    return 1
  fi

  # Clean up archive after extraction
  log info "Extraction successful, removing downloaded archive $archive"
  rm "$archive"

  log info "Archive $archive extracted successfully"
  echo "EXTRACTED_PATH=$final_dest"
  return 0
}
