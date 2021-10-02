FROM denis256/base-generic:0.0.2
USER root

RUN apt-get -y update && apt-get -y install ssh curl wget vim nano && apt-get clean

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.22.0/bin/linux/amd64/kubectl
RUN cp kubectl /usr/bin && chmod +x /usr/bin/kubectl

RUN wget https://get.helm.sh/helm-v3.7.0-linux-amd64.tar.gz && tar xfvz helm-v3.7.0-linux-amd64.tar.gz && cp linux-amd64/* /usr/bin
