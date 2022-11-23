FROM ubuntu:20.04
USER root

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get install -y --no-install-recommends ca-certificates tzdata ssh telnet mc wget curl gettext-base rsync && apt-get clean

RUN mkdir /tmp/downloads

WORKDIR /tmp/downloads

ENV KUBECTL_VERSION=v1.23.0
RUN wget https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -O /usr/bin/kubectl
RUN chmod +x /usr/bin/kubectl

ENV HELM_VERSION=v3.10.2
RUN wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
RUN tar xfvz helm-${HELM_VERSION}-linux-amd64.tar.gz
RUN mv linux-amd64/helm /usr/local/bin/helm

WORKDIR /
RUN rm -rf /tmp/downloads

