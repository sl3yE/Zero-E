#!/usr/bin/env bash
#Adds Zero-E to $PATH

#Set default installation directory
install_dir="/usr/local/bin"

#Parse command line options
while getopts ":b:" opt; do
  case $opt in
    b)
      install_dir="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

#Create the installation directory if it doesn't exist
mkdir -p "$install_dir"

#Copy Zero-E to the installation directory
sudo cp ./zero-e "$install_dir/zeroe" && sudo chmod +x "$install_dir/zeroe"
exitstatus=$?

if [ $exitstatus -eq 0 ]; then
    echo -e "\e[32m [+] Zero-E copied to $install_dir/zeroe \e[0m"
    echo -e "\e[36m [-] Zero-E can now be ran with '\e[32mzeroe [options]\e[36m' from anywhere, as you would any other command \e[0m"
else
    echo -e "\e[31m [!] Failed to install Zero-E \e[0m"
fi