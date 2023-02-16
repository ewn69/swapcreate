#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

# Define swap file location
swap_file=/swapfile

# Check if swap file exists
if [ -f "$swap_file" ]; then
  # Prompt user to confirm swap file removal
  echo "Do you want to remove the swap file $swap_file? [Y/N]"
  read confirmation

  # Convert input to lowercase
  confirmation="$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')"

  if [ "$confirmation" = "y" ]; then
    # Check if swap is enabled and disable if necessary
    if swapon -s | grep -q "$swap_file"; then
      swapoff "$swap_file"
    fi

    # Remove swap file and entry in /etc/fstab
    rm "$swap_file" && sed -i "/$swap_file/d" /etc/fstab
    echo "Swap file $swap_file has been removed successfully."
  else
    echo "Cancelled."
    exit 0
  fi
else
  echo "Swap file $swap_file does not exist."
  exit 0
fi
