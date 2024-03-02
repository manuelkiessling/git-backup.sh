#!/bin/bash

# Setup test environment
mkdir -p test_env
cd test_env

# Define the remote repository URL
echo "https://github.com/github/gitignore.git" > repositories.conf

# Run the backup script
bash ../backup.sh

# Define the expected directory for the local mirror
local_mirror_dir="local_mirrors/github.com/github/gitignore.git"

# Verify the backup
if [ -f "$local_mirror_dir/config" ]; then
    echo "Backup successful"
else
    echo "Backup failed"
    exit 1
fi

# Cleanup test environment
cd ..
rm -rf test_env
