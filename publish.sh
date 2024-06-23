#!/bin/bash

# Set options to exit immediately if any command fails (-e) and treat unset variables as errors (-u)
set -eu

output_dir="Releases"
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

# Function to find file with type in subdirectories
find_file() {
    local file_type="$1"
    local search_dir="$2"
    if [ -z "$search_dir" ]; then
        search_dir="."
    fi

    local target_file
    target_file=$(find . -type f -name "*.$file_type" | head -n 1)

    if [ -z "$target_file" ]; then
        return 1
    else
        echo "$target_file"
        return 0
    fi
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

# Find csproj file path
csproj=$(find_file "csproj" ".")
if [ -z "$csproj" ]; then
    read -rp "Please enter the path where the .csproj file is located: " user_path

    if [ -z "$user_path" ]; then
        echo "No path entered. Exiting."
        exit 1
    fi

    if [ -d "$user_path" ]; then
        csproj=$(find "$user_path" -type f -name '*.csproj' | head -n 1)
        if [ -z "$csproj" ]; then
            echo "No .csproj file found in the specified path: $user_path"
            exit 1
        fi
    else
        if [ ! -f "$user_path" ]; then
            echo "Invalid path: $user_path does not exist."
            exit 1
        fi
    fi
fi

# Build package
dotnet pack "$csproj" -c Release -o "$output"
echo ""
echo "Package build in: $output/"

if get_confirm "Do you want to publish it to nuget manually"; then
    nupkg=$(find_file "nupkg" $output_dir)
    if [ -z "$nupkg" ]; then
        echo "Can not find .nupkg file to publish."
        read -rp "nupkg file path: " nupkg
    fi

    read -rsp "Enter your api key: " SECRET_KEY
    dotnet nuget push "$nupkg" --source "https://api.nuget.org/v3/index.json" --api-key "$SECRET_KEY"
fi
