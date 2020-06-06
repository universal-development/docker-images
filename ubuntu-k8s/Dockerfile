FROM ubuntu:18.04
USER root

RUN apt-get -y update && apt-get -y install ssh curl wget vim nano && apt-get clean

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kubectl
RUN cp kubectl /usr/bin && chmod +x /usr/bin/kubectl

RUN wget https://storage.googleapis.com/kubernetes-helm/helm-v2.12.1-linux-amd64.tar.gz && tar xfvz helm-v2.12.1-linux-amd64.tar.gz && cp linux-amd64/* /usr/bin
