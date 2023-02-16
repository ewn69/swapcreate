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
  echo "=========================================="
  echo "Free Memory:"
  free -m
  echo "=========================================="
}

# Function to show free disk space
show_free_disk_space() {
  echo "=========================================="
  echo "Free Disk Space:"
  df -h | awk '$NF=="/"{printf "%s", $4}'
  echo ""
  echo "=========================================="
}

# Ask user for swap size
echo "How many GB of swap space do you want to create? [ ex: 8 ]"
read swap_size

# Validate input swap size
if ! [[ "$swap_size" =~ ^[0-9]+$ ]]; then
  echo "Invalid input. Please enter a valid integer."
  exit 1
fi

if [ "$swap_size" -gt 128 ]; then
  echo "Swap size cannot exceed 128GB."
  exit 1
fi

# Check disk space availability
if ! df / | awk '{print $4}' | tail -1 | awk '{ if ($1 < '$swap_size'000000) exit 1 }'; then
  echo "Not enough disk space available for swap creation."
  exit 1
fi

# Confirm swap creation
echo "Do you want to create a $swap_size GB swap file? [Y/N]"
read confirmation

if [ "$confirmation" = "Y" ] || [ "$confirmation" = "y" ]; then
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
  
  # Show free memory and free disk space
  show_free_memory
  show_free_disk_space
  
  echo "[ ! ] - Swap file created successfully!"
else
  echo "Cancelled."
fi
