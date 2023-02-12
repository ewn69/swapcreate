#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

echo "How many GB of swap space do you want to create?"
read swap_size

echo "Do you want to create a $swap_size GB swap file? [Y/N]"
read confirmation

if [ "$confirmation" = "Y" ] || [ "$confirmation" = "y" ]; then
  sudo fallocate -l "$swap_size"G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab
  echo "Swap file created successfully!"
else
  echo "Cancelled."
fi
