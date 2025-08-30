# docker-images

Repository with docker images

Build locally for testing:
```
just container aws-cli
```

## Release process

* tag commit with <image-dir>-<version>

* push image `just push aws-cli` or through CICD

## Just usage

### Build a Docker image
```
just container <image-directory>
```
Example:
```
just container ubuntu-ssh-server
```

### Push a Docker image to the repository
```
just push <image-directory>
```
Example:
```
just push ubuntu-ssh-server
```

Images are tagged using .cicd/image-tag.sh logic (same as previous Makefile).
