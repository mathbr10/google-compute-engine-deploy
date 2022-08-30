#!/bin/bash

# set -euxo pipefail

# # install CUDA
# if which nvidia-smi
# then
#   exit
# fi

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

# # remove this if this does not work
groupadd docker
usermod -aG docker $USER

# Install nvidia-container-runtime
# https://stackoverflow.com/questions/25185405/using-gpu-from-a-docker-container
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  tee /etc/apt/sources.list.d/nvidia-docker.list
apt-get update
systemctl restart docker

# Install nvidia-docker2 and reload the Docker daemon configuration
apt-get install -y nvidia-docker2
pkill -SIGHUP dockerd
systemctl restart docker

# setup credentials for gcr.io
# in this moment we can  se gcr.io in the docker credentials file with the command $HOME/.docker/config.json
# https://cloud.google.com/container-registry/docs/advanced-authentication
curl -fsSL "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v${VERSION}/docker-credential-gcr_${OS}_${ARCH}-${VERSION}.tar.gz" \
| tar xz docker-credential-gcr \
&& chmod +x docker-credential-gcr && sudo mv docker-credential-gcr /usr/bin/

# # docker-credential-gcr configure-docker
# curl -fsSL "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v2.1.5/docker-credential-gcr_linux_amd64-2.1.5.tar.gz" \
# | tar xz docker-credential-gcr \
# && chmod +x docker-credential-gcr && sudo mv docker-credential-gcr /usr/bin/
# docker-credential-gcr configure-docker

docker pull ${IMAGE_TAG}
docker run -e BENTOML_PORT=3000 -p 3000:3000 --gpus all --restart always ${IMAGE_TAG}