# docker-images

Repository with docker images

Build locally for testing:
```
make container image=aws-cli
```

## Release process

* tag commit with <image-dir>-<version>

* push image `make push image=aws-cli` or through CICD

