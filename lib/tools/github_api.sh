#!/bin/bash

# Extract owner and repo from GitHub URL
# Usage: parse_github_url <url>
# Outputs: owner repo (space-separated)
parse_github_url() {
  local url="$1"

  url="${url%.git}" # Remove .git suffix if present

  if [[ "$url" =~ github\.com[/:]([^/]+)/([^/#?]+) ]]; then
    local owner="${BASH_REMATCH[1]}"
    local repo="${BASH_REMATCH[2]}"
    echo "$owner $repo"
    return 0
  fi

  return 1
}

# Handle GitHub API rate limiting by reading information in header files
# Usage: handle_rate_limit <response_headers_file>
handle_rate_limit() {
  local headers_file="$1"

  if [ ! -f "$headers_file" ]; then
    return 0
  fi

  # Check if we're rate limited
  local status_code
  status_code=$(grep -i "^HTTP/" "$headers_file" | tail -1 | awk '{print $2}')

  if [[ "$status_code" = "403" || "$status_code" = "429" ]]; then
    local reset_time
    reset_time=$(grep -i "^x-ratelimit-reset:" "$headers_file" | awk '{print $2}' | tr -d '\r') # Extract rate limit reset time

    if [[ -n "$reset_time" ]]; then # If a timeout wait time is found
      local current_time
      current_time=$(date +%s)
      local wait_time=$((reset_time - current_time + 5))

      if [[ "$wait_time" -gt 0 ]]; then
        echo "GitHub API rate limit hit. Waiting ${wait_time}s..."
        sleep "$wait_time"
        return 0
      fi
    fi
  fi

  return 0
}

# Get the latest release version from GitHub
# Usage: get_latest_release_version <owner> <repo>
# Outputs: version tag (e.g., v1.2.3)
get_latest_release_version() {
  local owner="$1"
  local repo="$2"
  local headers_file
  headers_file=$(mktemp)

  local api_url="https://api.github.com/repos/$owner/$repo/releases/latest"
  local response
  response=$(curl -sS -D "$headers_file" "$api_url" 2>&1)
  local curl_exit=$?

  handle_rate_limit "$headers_file"
  rm -f "$headers_file"

  if [[ "$curl_exit" -ne 0 ]]; then
    log_error "Failed to fetch latest release for $owner/$repo"
    return 1
  fi

  # Parse tag_name from JSON response
  local version
  version=$(echo "$response" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

  if [ -z "$version" ]; then
    log_error "Could not parse version from GitHub API response"
    return 1
  fi

  echo "$version"
  return 0
}

# Get release asset download URL matching a pattern
# Usage: get_release_asset_url <owner> <repo> <version> <pattern>
# Outputs: download URL
get_release_asset_url() {
  local owner="$1"
  local repo="$2"
  local version="$3"
  local pattern="$4"
  local headers_file
  headers_file=$(mktemp)

  local api_url="https://api.github.com/repos/$owner/$repo/releases/tags/$version"
  local response
  response=$(curl -sS -D "$headers_file" "$api_url" 2>&1)
  local curl_exit=$?

  handle_rate_limit "$headers_file" # Make sure we aren't in GitHub API timeout
  rm -f "$headers_file"

  if [[ "$curl_exit" -ne 0 ]]; then
    echo "Failed to fetch release $version for $owner/$repo"
    return 1
  fi

  # Convert wildcard pattern to grep pattern
  local grep_pattern="${pattern//\*/.*}"

  # Extract all asset names and URLs
  local assets
  assets=$(echo "$response" | grep -o '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

  # Find matching asset
  local matched_url
  while IFS= read -r url; do
    local filename
    filename=$(basename "$url")
    if [[ "$filename" =~ ^${grep_pattern}$ ]]; then
      matched_url="$url"
      break
    fi
  done <<< "$assets"

  if [[ -z "$matched_url" ]]; then
    echo "No asset matching pattern '$pattern' found in release $version"
    return 1
  fi

  echo "$matched_url"
  return 0
}
