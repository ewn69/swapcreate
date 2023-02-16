#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

# Check if fallocate is installed, and install if not
if ! command -v fallocate &> /dev/null; then
  echo "fallocate is not installed. Installing Coreutils..."
  apt-get update &> /dev/null && apt-get install -y coreutils &> /dev/null
  if [ $? -ne 0 ]; then
    echo "Failed to install fallocate."
    exit 1
  fi
fi

# Function to show free memory
show_free_memory() {
  echo "Free Memory:"
  free -m
}

# Function to show free disk space in GB
show_free_disk_space() {
  echo "Free Disk Space:"
  df -h --output=avail /
}

# Ask user for swap size
echo "How many GB of swap space do you want to create? [ ex: 8 ]"
read swap_size

# Check if swap size is within limit (128 GB)
if [ "$swap_size" -gt 128 ]; then
  echo "Swap size cannot be more than 128 GB."
  exit 1
fi

# Confirm swap creation
echo "Do you want to create a $swap_size GB swap file? [Y/N]"
read confirmation

if [ "$confirmation" = "Y" ] || [ "$confirmation" = "y" ]; then
  # Check if enough disk space is available
  required_disk_space=$((swap_size*2)) # Double swap size for safety margin
  available_disk_space=$(df --output=avail / | tail -n 1)
  if [ "$required_disk_space" -gt "$available_disk_space" ]; then
    echo "Not enough free disk space available to create swap file."
    show_free_disk_space
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
  
  echo "Swap file created successfully!"
else
  echo "Cancelled."
fi
