#!/bin/bash

# Run ldd on the executable and capture the output
executable="$1"
if [ -z "$executable" ]; then
    echo "Usage: $0 <executable_path>"
    exit 1
fi

output=$(ldd "$executable")

# Extract paths starting with /export/dump/ulrich
paths=$(echo "$output" | grep -o '/export/dump/ulrich/\S*')

# Replace /export/dump/ulrich with /import/heisenbug-dump/ulrich
new_paths=$(echo "$paths" | sed 's|/export/dump/ulrich|/import/heisenbug-dump/ulrich|g')

# Extract directory paths and make them unique
dir_paths=$(echo "$new_paths" | xargs -n 1 dirname | sort -u)

# Generate a string of paths separated by colon
new_ld_library_path=$(echo "$dir_paths" | tr '\n' ':' | sed 's/:$//')

# Update LD_LIBRARY_PATH in the parent shell
export LD_LIBRARY_PATH="$new_ld_library_path"

echo "please use:"
echo export LD_LIBRARY_PATH="$new_ld_library_path":\$LD_LIBRARY_PATH
