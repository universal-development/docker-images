FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive


RUN apt-get update && \
    apt-get install -yq curl wget git ansible python3 python3-pip

RUN apt-get install -yq python3-pip

RUN pip3 --no-cache-dir install --upgrade awscli

RUN apt-get install -yq apt-transport-https ca-certificates gnupg

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | tee /usr/share/keyrings/cloud.google.gpg
RUN apt-get update && apt-get -yq install google-cloud-cli

RUN mkdir /tmp/downloads
WORKDIR /tmp/downloads

RUN apt-get install -yq unzip

# Download terraform
ENV terraform_version=1.2.9
RUN wget https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip

RUN unzip terraform_${terraform_version}_linux_amd64.zip
RUN mv terraform /usr/local/bin/
RUN terraform --version 

# Download terragrunt
ENV terragrunt_version=v0.39.0
RUN wget https://github.com/gruntwork-io/terragrunt/releases/download/${terragrunt_version}/terragrunt_linux_amd64 -O /usr/bin/terragrunt
RUN chmod +x /usr/bin/terragrunt

# Download kubectl
ENV kubectl_version=v1.25.2
RUN wget https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl -O /usr/bin/kubectl
RUN chmod +x /usr/bin/kubectl

# Download helm
ENV helm_version=v3.10.0
RUN wget https://get.helm.sh/helm-${helm_version}-linux-amd64.tar.gz
RUN tar xfvz helm-${helm_version}-linux-amd64.tar.gz
RUN mv linux-amd64/helm /usr/local/bin/helm

WORKDIR /
RUN rm -rf /tmp/downloads

RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update
RUN apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

RUN apt-get install -y build-essential

RUN apt-get install -y make

RUN apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin


