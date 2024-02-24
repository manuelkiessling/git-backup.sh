#!/bin/bash

config_file="repositories.conf"

# Function to parse the repository URL and construct the desired directory path
parse_repo_url() {
    local url="$1"
    local host repo_path

    if [[ "$url" =~ ^https?:// ]]; then
        # Extract host, project, and repo name for HTTPS URLs
        host=$(echo "$url" | sed -E 's/https?:\/\/([^@]+@)?([^\/]+)\/(.*)/\2/')
        repo_path=$(echo "$url" | sed -E 's/https?:\/\/([^@]+@)?([^\/]+)\/(.*)/\3/')
    else
        # Extract host, project, and repo name for SSH URLs
        host=$(echo "$url" | sed -E 's/git@([^:]+):(.*)/\1/')
        repo_path=$(echo "$url" | sed -E 's/git@([^:]+):(.*)/\2/')
    fi

    # Construct and echo the directory path
    echo "${host}/${repo_path}"
}

# Function to process each repository line
process_repository_line() {
    local line="$1"

    # Skip blank lines and lines starting with #
    if [[ -z "$line" || "$line" =~ ^# ]]; then
        return
    fi

    local source_repo target_repo label target_url repo_dir

    source_repo=$(echo "$line" | awk '{print $1}')
    target_repo=$(echo "$line" | awk '{print $2}')
    repo_dir="local_mirrors/$(parse_repo_url "$source_repo")"

    # Step 1: Clone or update the local git mirror
    if [ ! -d "$repo_dir" ]; then
        echo "Cloning mirror for $source_repo into $repo_dir"
        git clone --mirror "$source_repo" "$repo_dir"
    else
        echo "Updating mirror for $source_repo"
        pushd "$repo_dir" > /dev/null || exit
        git fetch
        popd > /dev/null || exit
    fi

    # Step 2: Push to secondary repo if specified
    if [ -n "$target_repo" ]; then
        label=$(echo "$target_repo" | cut -d':' -f1)
        target_url=$(echo "$target_repo" | cut -d':' -f2-)

        echo "Adding remote $label with URL $target_url"
        pushd "$repo_dir" > /dev/null || exit
        git remote add "$label" "$target_url" 2>/dev/null || true
        git push --all "$label"
        git push --tags "$label"
        popd > /dev/null || exit
    fi
}

# Process each line in the config file
while IFS= read -r line; do
    process_repository_line "$line"
done < "$config_file"
