#!/bin/bash

# Function to show system info
show_system_info() {
  echo "######################################################################"
  echo "* SwapCreate @ v69.9"
  echo "*"
  echo "* Made by ewn"
  echo "*"
  echo "* Running on $(lsb_release -ds)"
  echo "######################################################################"
  echo
}

# Check system info
show_system_info

# Function to show free memory
show_free_memory() {
  echo "=========================================="
  echo "* Free Memory:"
  free -m
  echo "=========================================="
}

# Function to show free disk space
show_free_disk_space() {
  echo "=========================================="
  echo "* Free Disk Space:"
  df -h | awk '$NF=="/"{printf "%s\n", $4}'
  echo "=========================================="
}

# Ask user for swap size
echo "* How many GB of swap space do you want to create? [ ex: 8 ] | Input 1-128:"
read swap_size

# Validate input
if ! [[ "$swap_size" =~ ^[1-9][0-9]?$|^128$ ]]; then
  echo "Invalid input. Please enter a value between 1 and 128."
  exit 1
fi

# Confirm swap creation
echo "* Do you want to create a $swap_size GB swap file? [Y/N]"
read confirmation

if [ "$confirmation" = "Y" ] || [ "$confirmation" = "y" ]; then
  # Check free disk space
  disk_space=$(df -k --output=avail / | tail -n 1)
  required_space=$((swap_size * 1024 * 1024))
  if [ $required_space -gt $disk_space ]; then
    echo "Not enough free disk space to create $swap_size GB swap file. Required: $required_space KB. Available: $disk_space KB."
    exit 1
  fi
  
  # Create swap file
  if ! fallocate -l "$swap_size"G /swapfile &> /dev/null; then
    echo "Failed to create swap file."
    exit 1
  fi
  
  # Set permissions and format swap file
  chmod 600 /swapfile &> /dev/null
  if ! mkswap /swapfile &> /dev/null; then
    echo "Failed to format swap file."
    exit 1
  fi
  
  # Enable swap file and set to mount on boot
  if ! swapon /swapfile &> /dev/null; then
    echo "Failed to enable swap file."
    exit 1
  fi
  echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab &> /dev/null
  
  # Show free memory and disk space
  show_free_memory
  show_free_disk_space
  
  echo "[ ! ] - Swap file created successfully!"
else
  echo "Cancelled."
fi
