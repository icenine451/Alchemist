#!/bin/bash

extractor_info() {
  echo "type:7z,zip,tar.gz,tgz,tar.bz2,tbz2,tar.xz,txz,tar"
}

extract() {
  local archive="$1"
  local dest="$2"
  local type="$3"

  local final_dest="$dest"

  case "$type" in
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
        tar -xzf "$1" -C "$2"
      }
      ;;
    tar.bz2|tbz2)
      extract_cmd() {
        tar -xjf "$1" -C "$2"
      }
      ;;
    tar.xz|txz)
      extract_cmd() {
        tar -xJf "$1" -C "$2"
      }
      ;;
    tar)
      extract_cmd() {
        tar -xf "$1" -C "$2"
      }
      ;;
    *)
      log error "Error: Unsupported archive type: $type"
      return 1
      ;;
  esac

  extract_cmd "$archive" "$final_dest"
}
