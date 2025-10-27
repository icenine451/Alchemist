#!/bin/bash

# The purpose of this script is the take an input component.json file, aquire the original package, extract it to a useable file structure, pick out the files/folders desired and re-archive it in a standard structure.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source tooling scripts
source "$SCRIPT_DIR/lib/defaults.sh"
source "$SCRIPT_DIR/lib/download.sh"
source "$SCRIPT_DIR/lib/extract.sh"
source "$SCRIPT_DIR/lib/assemble.sh"
source "$SCRIPT_DIR/lib/archive.sh"

log() {
  echo "[$1] $2" >&2
}

transmute() {
  component_recipe_file=$(realpath "$1")
  workdir="${2:-$DEFAULT_WORKDIR}"
  workdir="$(realpath "$workdir")"

  # component_recipe.json file information extraction
  component_recipe_contents=$(jq -r '.' "$component_recipe_file")
  component_name="$(jq -r '. | keys[]' <<< $component_recipe_contents)"

  if [[ -d "$workdir" ]]; then # If a workdir already exists, clear it
    rm -rf "$workdir"
  fi

  COMPONENT_ARTIFACT_ROOT="$workdir/$component_name-artifact" # Initialize the final destination for kept files
  mkdir -p "$COMPONENT_ARTIFACT_ROOT"

  combined_sources_array=$(echo "$component_recipe_contents" | jq -c '
    .[] as $parent |
    ([$parent] + ($parent.additional_sources // [])) |
    map(del(.additional_sources))
  ')

  while read -r source_obj; do
    source_type="$(jq -r '.source_type' <<< $source_obj)"
    source_url="$(jq -r '.source_url' <<< $source_obj)"
    source_version="$(jq -r '.version' <<< $source_obj)"
    source_dest="$(jq -r '.dest//empty' <<< $source_obj)"
    extraction_type="$(jq -r '.extraction_type' <<< $source_obj)"

    if [[ ! -n "$source_dest" ]]; then
      source_dest="$workdir"
    fi

    # Download stage for this object
    download_result=$(download_cli -t "$source_type" -u "$source_url" -d "$source_dest" -v "$source_version")
    downloaded_file=$(echo "$download_result" | grep "^DOWNLOADED_FILE=" | cut -d= -f2)

    # Extraction stage for this object
    extraction_result=$(process_extract -f "$downloaded_file" -d "$source_dest" -t "$extraction_type")
    extracted_path=$(echo "$extraction_result" | grep "^EXTRACTED_PATH=" | cut -d= -f2)
  done < <(echo "$combined_sources_array" | jq -c '.[]')
}

transmute "$@"
