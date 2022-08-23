#!/bin/bash

docker pull $1:$2
docker run -p 3000:3000 --gpus all $1:$2