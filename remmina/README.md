# Docker image with remmina

Docker image with PAC ssh connection manager

xhost +

docker run -it -e DISPLAY=$DISPLAY  -v /tmp/.X11-unix:/tmp/.X11-unix  --rm denis256/remmina:0.0.1 remmina

