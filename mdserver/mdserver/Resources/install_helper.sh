#!/bin/sh

#  install_helper.sh
#  mdserver-mac

cd "$(dirname "${BASH_SOURCE[0]}")"
USER=$(who | sed -n "2,1p" |awk '{print $1}')

sudo mkdir -p "/Library/Application Support/mdserver/"
sudo cp addhost "/Library/Application Support/mdserver/"
sudo cp removehost "/Library/Application Support/mdserver/"
sudo chown {$USER}:admin "/Library/Application Support/mdserver/addhost"
sudo chmod a+rx "/Library/Application Support/mdserver/addhost"
sudo chmod +s "/Library/Application Support/mdserver/addhost"

sudo chown {$USER}:admin "/Library/Application Support/mdserver/removehost"
sudo chmod a+rx "/Library/Application Support/mdserver/removehost"
sudo chmod +s "/Library/Application Support/mdserver/removehost"

echo done
