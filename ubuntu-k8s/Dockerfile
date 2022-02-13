FROM ubuntu:20.04
USER root

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get install -y --no-install-recommends ca-certificates tzdata ssh telnet mc wget curl gettext-base rsync && apt-get clean

RUN mkdir /tmp/downloads

WORKDIR /tmp/downloads

RUN wget https://dl.k8s.io/release/v1.23.0/bin/linux/amd64/kubectl -O /usr/bin/kubectl
RUN chmod +x /usr/bin/kubectl

RUN wget https://get.helm.sh/helm-v3.7.2-linux-amd64.tar.gz
RUN tar xfvz helm-v3.7.2-linux-amd64.tar.gz
RUN mv linux-amd64/helm /usr/local/bin/helm

WORKDIR /
RUN rm -rf /tmp/downloads

