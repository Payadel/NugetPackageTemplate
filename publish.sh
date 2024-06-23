#!/bin/bash

# Set options to exit immediately if any command fails (-e) and treat unset variables as errors (-u)
set -eu

output_dir="artifacts"
output="$output_dir/$(date "+%Y-%m-%d_%H-%M-%S")"

# Function to check if a directory is empty
# Usage: is_directory_empty DIRECTORY_PATH
is_directory_empty() {
    local dir="$1"
    if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
        return 0 # Directory is empty
    else
        return 1 # Directory is not empty
    fi
}

# Function to ask for user confirmation
# Usage: confirm_delete DIRECTORY_PATH
get_confirm() {
    local message="$1"
    read -rp "$message (y/N): " choice

    case "$choice" in
    y | Y) return 0 ;;
    *) return 1 ;;
    esac
}
#========================================================================
# main

# Delete old releases if exists
if ! is_directory_empty "$output_dir"; then
    if get_confirm "Directory '$output_dir' is not empty. Do you want to delete it?"; then
        rm -r "$output_dir"
    fi
fi

# Create new directory for new release
mkdir -p "$output"

# Build package
dotnet pack src --configuration Release --output "$output"
echo ""
echo "Output: $output/"

if get_confirm "Do you want to publish it to nuget manually"; then
    read -rsp "Enter your api key: " SECRET_KEY
    dotnet nuget push "$output/*.nupkg" --api-key $SECRET_KEY --source https://api.nuget.org/v3/index.json
fi
