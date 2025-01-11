# linkhub

Collection of tools to connect to remote environments.

### Local testing

Local build and testing

```bash
docker build . -t linkhub
xhost +
docker run -it -e DISPLAY=$DISPLAY  -v /tmp/.X11-unix:/tmp/.X11-unix --rm linkhub bash
```