#!/bin/bash

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared libraries
source "$SCRIPT_DIR/tools/download_retry.sh"
source "$SCRIPT_DIR/tools/url_resolver.sh"
source "$SCRIPT_DIR/tools/github_api.sh"
source "$SCRIPT_DIR/defaults.sh"

# Create dictionaries for downloader registry
declare -A DOWNLOADER_TYPES
declare -A DOWNLOADER_DESCRIPTIONS
declare -A DOWNLOADER_FILES


load_downloaders() {
  local downloader_dir="$SCRIPT_DIR/downloaders"

  if [[ ! -d "$downloader_dir" ]]; then
    echo "Downloaders directory not found: $downloader_dir"
    return 1
  fi

  for downloader_file in "$downloader_dir"/*.sh; do
    if [ ! -f "$downloader_file" ]; then
      continue
    fi

    local filename
    filename=$(basename "$downloader_file")

    source "$downloader_file"

    if ! declare -f downloader_info > /dev/null; then # Check if downloader_info function exists
      echo "Downloader $filename does not implement downloader_info()"
      continue
    fi

    # Parse downloader info
    local info
    info=$(downloader_info)

    local types description
    types=$(echo "$info" | grep "^type:" | cut -d: -f2)
    description=$(echo "$info" | grep "^description:" | cut -d: -f2-)

    if [[ ! -n "$types" ]]; then
      echo "Downloader $filename does not specify any types"
      continue
    fi

    # Register each type this downloader handles
    IFS=',' read -ra TYPE_ARRAY <<< "$types"
    for type in "${TYPE_ARRAY[@]}"; do
      type=$(echo "$type" | xargs)  # Trim whitespace
      DOWNLOADER_TYPES["$type"]="$filename"
      DOWNLOADER_FILES["$filename"]="$downloader_file"
    done

    DOWNLOADER_DESCRIPTIONS["$filename"]="$description"

    echo "Loaded downloader: $filename (types: $types)"
  done
}

parse_args() {
  type=""
  url=""
  dest=""
  version=""
  max_retries=3
  initial_delay=2
  max_delay=30

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--type)
        type="$2"
        shift 2
        ;;
      -u|--url)
        url="$2"
        shift 2
        ;;
      -d|--dest)
        dest="$2"
        shift 2
        ;;
      -v|--version)
        version="$2"
        shift 2
        ;;
      --max-retries)
        max_retries="$2"
        shift 2
        ;;
      --initial-delay)
        initial_delay="$2"
        shift 2
        ;;
      --max-delay)
        max_delay="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
  done

  # Validate required arguments
  if [[ ! -n "$type" || ! -n "$url" || ! -n "$dest" || ! -n "$version" ]]; then
    echo "Missing required arguments"
    exit 1
  fi
}

download() {
  load_downloaders

  parse_args "$@"

  if [[ ! -n "${DOWNLOADER_TYPES[$type]:-}" ]]; then # Find appropriate downloader for the specified type
    echo "No downloader found for type: $type"
    exit 1
  fi

  local downloader_file="${DOWNLOADER_TYPES[$type]}" # Pull the appropriate downloader module from the dictionary
  source "$SCRIPT_DIR/downloaders/$downloader_file"
  echo "Using downloader: $downloader_file"

  if ! download "$url" "$dest" "$version" "$type" "$max_retries" "$initial_delay" "$max_delay"; then
    echo "Download failed"
    exit 1
  fi

  return 0
}
