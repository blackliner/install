#!/bin/bash

set -euo pipefail

distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/experimental/$distribution/libnvidia-container.list | \
         sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
         sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update

if ! command -v docker &> /dev/null
then
    curl -sSL get.docker.com | sudo bash
    sudo systemctl --now enable docker
    sudo docker run hello-world
fi

sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker

echo "Now run:"
echo "sudo docker run --rm -it --gpus all blackliner/gpu_burn:latest"

