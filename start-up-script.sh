#!/bin/bash

# install CUDA
if which nvidia-smi
then
  exit
fi

mkdir -p /opt/google
cd /opt/google || exit

if ! which python3 > /dev/null
then
  if which yum > /dev/null
  then
    yum install -y python3
  else
    apt-get install -y python3
  fi
fi

curl https://raw.githubusercontent.com/GoogleCloudPlatform/compute-gpu-installation/main/linux/install_gpu_driver.py --output install_gpu_driver.py
python3 install_gpu_driver.py

# Install docker
apt-get update
apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y docker-ce

# remove this if this does not work
groupadd docker
usermod -aG docker $USER

# Install nvidia-container-runtime
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  tee /etc/apt/sources.list.d/nvidia-docker.list
apt-get update

# Install nvidia-docker2 and reload the Docker daemon configuration
apt-get install -y nvidia-docker2
pkill -SIGHUP dockerd

#docker pull $1:$2
docker run -p 3000:3000 --gpus all $1:$2