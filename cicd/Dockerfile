FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# base packages
RUN apt-get update && \
    apt-get install -yq unzip curl wget git ansible python3 python3-pip rsync build-essential make mc apt-transport-https ca-certificates gnupg 

# python
RUN apt-get install -yq python3-pip

# docker client
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update
RUN apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin 

# AWS
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm awscliv2.zip 
RUN aws --version

# Google SDK
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN apt-get update && apt-get -yq install google-cloud-cli  google-cloud-sdk-gke-gcloud-auth-plugin

RUN mkdir /tmp/downloads
WORKDIR /tmp/downloads

# Download terraform
RUN mkdir ~/.tfenv
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
RUN echo 'export PATH="${HOME}/.tfenv/bin:${PATH}"' >> ~/.bash_profile

# Download terragrunt
RUN mkdir ~/.tgenv
RUN git clone --depth=1 https://github.com/cunymatthieu/tgenv.git ~/.tgenv
RUN echo 'export PATH="$HOME/.tgenv/bin:$PATH"' >> ~/.bash_profile

ENV PATH=/root/.tfenv/bin:/root/.tgenv/bin:$PATH

# Download kubectl
ENV kubectl_version=v1.30.2
RUN wget https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl -O /usr/bin/kubectl
RUN chmod +x /usr/bin/kubectl

# Download helm
ENV helm_version=v3.15.3
RUN wget https://get.helm.sh/helm-${helm_version}-linux-amd64.tar.gz
RUN tar xfvz helm-${helm_version}-linux-amd64.tar.gz
RUN mv linux-amd64/helm /usr/local/bin/helm

WORKDIR /
RUN rm -rf /tmp/downloads

RUN tfenv install 1.9.0
RUN tgenv install 0.67.3
RUN tfenv use 1.9.0

RUN groupadd user && groupadd guide
RUN useradd -m -u 1001 -g user -G guide -s /bin/bash user


