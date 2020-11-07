# Docker image with PAC

Docker image with PAC ssh connection manager

xhost +

docker run -it -e DISPLAY=$DISPLAY  -v /tmp/.X11-unix:/tmp/.X11-unix  --rm denis256/pac:0.0.1 pac

