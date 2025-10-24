#!/bin/bash

# The purpose of this script is the take an input component.json file, aquire the original package, extract it to a useable file structure, pick out the files/folders desired and re-archive it in a standard structure.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source tooling scripts
source "$SCRIPT_DIR/lib/defaults.sh"
source "$SCRIPT_DIR/lib/logger.sh"
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

  COMPONENT_ARTIFACT_ROOT="$workdir/$component_name-artifact" # Initialize the final destination for kept files
  export "$COMPONENT_ARTIFACT_ROOT" # Export for use across all stages

  combined_sources_array=$(echo "$component_recipe_contents" | jq -c '
    .[] as $parent |
    ([$parent] + ($parent.additional_sources // [])) |
    map(del(.additional_sources))
  ')

  echo "$combined_sources_array" | jq -c '.[]' | while read -r source_obj; do
    source_type="$(jq -r '.source_type' <<< $source_obj)"
    source_url="$(jq -r '.source_url' <<< $source_obj)"
    source_version="$(jq -r '.version' <<< $source_obj)"

    result=$(download_cli -t "$source_type" -u "$source_url" -d "$workdir" -v "$source_version")
    downloaded_file=$(echo "$result" | grep "^DOWNLOADED_FILE=" | cut -d= -f2)

    source_extraction_type="$(jq -r '.extraction_type' <<< $source_obj)"
  done
}

transmute "$@"
