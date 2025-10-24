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

transmute() {
  component_recipe_file=$(realpath "$1")
  workdir=$(realpath -m "$2")

  # component_recipe.json file information extraction
  component_recipe_contents=$(jq -r '.' "$component_recipe_file")
  component_name="$(jq -r '. | keys[]' <<< $component_recipe_contents)"
  component_source_type="$(jq -r '.[].source_type' <<< $component_recipe_contents)"
  component_source_url="$(jq -r '.[].source_url' <<< $component_recipe_contents)"
  component_version="$(jq -r '.[].version' <<< $component_recipe_contents)"
  component_extraction_type="$(jq -r '.[].extraction_type' <<< $component_recipe_contents)"

  mkdir -p "$workdir" # Initialize the work area

  download_cli -t "$component_source_type" -u "$component_source_url" -d "$workdir" -v "$component_version"

  if [[ ! -z "$component_additional_sources" ]]; then # If there are additional source files to download
    echo "$component_additional_sources" | jq -c '.[]' | while read -r additional_source_obj; do
      additional_source_type="$(jq -r '.source_type' <<< $additional_source_obj)"
      additional_source_url="$(jq -r '.source_url' <<< $additional_source_obj)"
      additional_source_version="$(jq -r '.version' <<< $additional_source_obj)"
      additional_source_extraction_type="$(jq -r '.extraction_type' <<< $additional_source_obj)"

      download_cli -t "$additional_source_type" -u "$additional_source_url" -d "$workdir" -v "$additional_source_version"
    done
  fi
}

transmute "$@"
