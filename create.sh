#!/bin/bash

# Check Ubuntu or Debian version
get_os_version() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "${ID}" == "ubuntu" ]]; then
      echo "Ubuntu ${VERSION_ID}"
    elif [[ "${ID}" == "debian" ]]; then
      echo "Debian ${VERSION_ID}"
    else
      echo "Unsupported distribution."
      exit 1
    fi
  else
    echo "Unsupported distribution."
    exit 1
  fi
}

# Print header
echo "######################################################################"
echo "* SwapCreate @ v69.9"
echo "*"
echo "* Made by ewn"
echo "*"
echo "* Running $(get_os_version)."
echo "######################################################################"

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "* This script must be run as root."
  exit 1
fi

# Check if fallocate is installed, and install if not
if ! command -v fallocate &> /dev/null; then
  echo "* fallocate is not installed. Installing Coreutils..."
  apt-get update &> /dev/null && apt-get install -y coreutils &> /dev/null
  if [ $? -ne 0 ]; then
    echo "* Failed to install fallocate."
    exit 1
  fi
fi

# Check if swap file already exists
if [ -f "/swapfile" ]; then
  echo "* Swap file /swapfile already exists. Do you want to remove and recreate it?"
  read -p "* Input [Y/N]: " confirmation
  if [ "$confirmation" != "Y" ] && [ "$confirmation" != "y" ]; then
    echo "* Cancelled."
    exit 0
  fi
  sudo swapoff /swapfile &> /dev/null
  sudo rm /swapfile &> /dev/null
  sudo sed -i '/\/swapfile/d' /etc/fstab &> /dev/null
fi

# Function to show free memory
show_free_memory() {
  echo "* =========================================="
  echo "* Free Memory:"
  free -m
}

# Function to show free disk space
show_free_disk_space() {
  echo "* =========================================="
  echo "* Free Disk Space:"
  df -h --output=avail /
}

# Ask user for swap size
echo "* How many GB of swap space do you want to create? [ ex: 8 ]"
read -p "* Input 1-128: " swap_size

# Validate swap size
if ! [[ "$swap_size" =~ ^[1-9][0-9]?$|^128$ ]]; then
  echo "* Invalid input. Swap size must be a number between 1-128."
  exit 1
fi

# Confirm swap creation
echo "* Do you want to create a $swap_size GB swap file?"
read -p "* Input [Y/N]: " confirmation

if [ "$confirmation" = "Y" ] || [ "$confirmation" = "y" ]; then
  # Create swap file
  if ! fallocate -l "$swap_size"G /swapfile &> /dev/null; then
    echo "* Failed to create swap file."
    exit 1
  fi
  
  # Set permissions and format swap file
  chmod 600 /swapfile &> /dev/null
  if ! mkswap /swapfile &> /dev/null; then
    echo "* Failed to format swap file."
    exit 1
  fi
  
# Enable swap file and set to mount on boot
if ! swapon /swapfile &> /dev/null; then
  echo "Failed to enable swap file."
  exit 1
fi
echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab &> /dev/null

# Show free memory
echo "* =========================================="
echo "* Free Memory:"
free -m

# Show free disk space
echo "* =========================================="
echo "* Free Disk Space:"
df -h --output=avail /

# Success message
echo "[ ! ] - Swap file created successfully!"
fi
