#!/bin/bash

# The purpose of this script is the take an input component.json file, aquire the original package, extract it to a useable file structure, pick out the files/folders desired and re-archive it in a standard structure.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source tooling scripts
source "$SCRIPT_DIR/lib/defaults.sh"
source "$SCRIPT_DIR/lib/tools/install_flatpak.sh"
source "$SCRIPT_DIR/lib/download.sh"
source "$SCRIPT_DIR/lib/extract.sh"
source "$SCRIPT_DIR/lib/assemble.sh"
source "$SCRIPT_DIR/lib/gather_lib.sh"
source "$SCRIPT_DIR/lib/archive.sh"

log() {
  echo "[$1] $2" >&2
}

transmute() {
  component_recipe_file=$(realpath "$1")
  WORKDIR="${2:-$DEFAULT_WORKDIR}"
  export WORKDIR="$(realpath "WORKDIR")"

  # component_recipe.json file information extraction
  component_recipe_contents=$(jq -r '.' "$component_recipe_file")
  component_name="$(jq -r '. | keys[]' <<< $component_recipe_contents)"

  if [[ -d "WORKDIR" ]]; then # If a workdir already exists, clear it
    rm -rf "WORKDIR"
  fi

  export COMPONENT_ARTIFACT_ROOT="WORKDIR/$component_name-artifact" # Initialize the final destination for kept files
  mkdir -p "$COMPONENT_ARTIFACT_ROOT"

  component_recipe_contents=$(echo "$component_recipe_contents" | envsubst) # Process placeholder variables in component recipe

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
      source_dest="WORKDIR"
    fi

    # Download stage for this object
    download_result=$(process_download -t "$source_type" -u "$source_url" -d "$source_dest" -v "$source_version")
    DOWNLOADED_FILE=$(echo "$download_result" | grep "^DOWNLOADED_FILE=" | cut -d= -f2)

    # Extraction stage for this object
    extraction_result=$(process_extract -f "$DOWNLOADED_FILE" -d "$source_dest" -t "$extraction_type")
    EXTRACTED_PATH=$(echo "$extraction_result" | grep "^EXTRACTED_PATH=" | cut -d= -f2)

    # Assemble stage for this object
    obj_assets="$(jq -r '.assets//empty' <<< $source_obj)"

    if [[ -n "$obj_assets" ]]; then
      while read -r asset_obj; do
        asset_type="$(jq -r '.type' <<< $asset_obj)"
        asset_source="$(jq -r '.source' <<< $asset_obj)"
        asset_dest="$(jq -r '.dest' <<< $asset_obj)"
        asset_root="$EXTRACTED_PATH"

        assembly_result=$(process_assemble -t "$asset_type" -s "$asset_source" -d "$asset_dest" -r "$asset_root")
      done < <(echo "$obj_assets" | jq -c '.[]')
    fi
    
    # Library gathering stage
    obj_libs=$(echo "$source_obj" | jq -c '.libs//empty')

    if [[ -n "$component_libs" ]]; then
      log info "Component has listed libs, collecting..."

      while read -r lib_obj; do
        lib_name="$(jq -r '.library//empty' <<< $lib_obj)"
        lib_runtime_name="$(jq -r '.runtime_name//empty' <<< $lib_obj)"
        lib_runtime_version="$(jq -r '.runtime_version//empty'<<< $lib_obj)"
        lib_source="$(jq -r '.source//empty' <<< $lib_obj)"
        lib_dest="$(jq -r '.dest//empty' <<< $lib_obj)"
        lib_source_root="$EXTRACTED_PATH"

        gather_lib_result=$(process_gather_lib -n "$lib_name" -d "$lib_dest" -rn "$lib_runtime_name" -rv "$lib_runtime_version" -s "$lib_source" -r "$lib_source_root")
      done < <(echo "$obj_libs" | jq -c '.[]')
    fi
  done < <(echo "$combined_sources_array" | jq -c '.[]')
}

transmute "$@"
