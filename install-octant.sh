#!/bin/sh

### installs latest version of octant

tag=$(curl --silent "https://api.github.com/repos/vmware-tanzu/octant/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
version=$(curl --silent "https://api.github.com/repos/vmware-tanzu/octant/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//')
echo $tag
echo $version

wget https://github.com/vmware-tanzu/octant/releases/download/$tag/octant_"${version}"_Linux-64bit.tar.gz
tar -xvf octant_"${version}"_Linux-64bit.tar.gz
cd octant_"${version}"_Linux-64bit
chmod 700 octant
sudo mv octant /usr/local/bin/octant
cd ..

rm octant_"${version}"_Linux-64bit.tar.gz

rm -rf octant_"${version}"_Linux-64bit
