#!/bin/bash

# Update all submodules to their latest version
echo "Updating submodules to their latest versions..."
git submodule update --remote

# Check if the submodule update succeeded
if [ $? -eq 0 ]; then
    echo "Submodules updated successfully."
else
    echo "Warning: Some submodules could not be updated (they may not be accessible to you)."
fi

# Call builder.sh
echo "Running builder.sh..."
./builder.sh
