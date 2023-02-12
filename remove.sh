#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

swap_file=/swapfile

if [ -f "$swap_file" ]; then
  echo "Do you want to remove the swap file $swap_file? [Y/N]"
  read confirmation

  if [ "$confirmation" = "Y" ] || [ "$confirmation" = "y" ]; then
    sudo swapoff "$swap_file"
    sudo rm "$swap_file"
    sudo sed -i '/\/swapfile/d' /etc/fstab
    echo "Swap file $swap_file has been removed successfully."
  else
    echo "Cancelled."
  fi
else
  echo "Swap file $swap_file does not exist."
fi
