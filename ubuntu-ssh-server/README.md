# ubuntu-ssh-server

Ubuntu-based Docker image with OpenSSH server.

## Features
- Ubuntu base image
- OpenSSH server installed
- Default SSH user: `root`, password: `rootroot`
- User and password can be configured at runtime via `SSH_USER` and `SSH_PASS` environment variables

## Build

Default root user:
```
docker build -t ubuntu-ssh-server .
```

## Run

Default root user and password:
```
docker run -d -p 2222:22 ubuntu-ssh-server
```

Custom user and password (set at runtime):
```
docker run -d -p 2222:22 -e SSH_USER=myuser -e SSH_PASS=mypassword ubuntu-ssh-server
```

The container will keep running with the SSH server active. To check logs or debug issues, use:
```
docker logs <container_id>
```

## SSH Access
Connect using the configured user and password:
```
ssh <user>@localhost -p 2222
```
