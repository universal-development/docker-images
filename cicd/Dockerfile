FROM ubuntu:24.04

ARG KUBECTL_VERSION=v1.32.3
ARG HELM_VERSION=v3.17.0
ARG HCLOUD_VERSION=v1.50.0
ARG TERRAFORM_VERSION=1.11.4
ARG TERRAGRUNT_VERSION=0.77.20
ARG CIVO_VERSION=1.2.1
ARG ALIYUN_VERSION=3.0.270
ARG USER_ID=1001

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PATH=/root/.tfenv/bin:/root/.tgenv/bin:$PATH

# Install base packages and tools in a single layer
# This reduces the number of layers and image size
RUN apt-get update && apt-get install -yq --no-install-recommends \
    unzip \
    curl \
    wget \
    git \
    ansible \
    python3 \
    python3-pip \
    rsync \
    build-essential \
    make \
    mc \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    restic \
    rclone \
    && rm -rf /var/lib/apt/lists/*

# Install Docker client
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws \
    && aws --version

# Install Google SDK
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
    && apt-get update \
    && apt-get install -yq --no-install-recommends google-cloud-cli google-cloud-sdk-gke-gcloud-auth-plugin \
    && rm -rf /var/lib/apt/lists/*

# Create a temporary working directory
WORKDIR /tmp/downloads

# Install tfenv and tgenv for Terraform and Terragrunt version management
RUN mkdir -p ~/.tfenv ~/.tgenv \
    && git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv \
    && git clone --depth=1 https://github.com/cunymatthieu/tgenv.git ~/.tgenv \
    && echo 'export PATH="${HOME}/.tfenv/bin:${PATH}"' >> ~/.bash_profile \
    && echo 'export PATH="$HOME/.tgenv/bin:$PATH"' >> ~/.bash_profile

# Install kubectl using the ARG value and create symbolic link 'k'
RUN wget https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -O /usr/bin/kubectl \
    && chmod +x /usr/bin/kubectl \
    && ln -s /usr/bin/kubectl /usr/local/bin/k \
    && kubectl version --client

# Install helm using the ARG value and create symbolic link 'h'
RUN wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && tar xfz helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/local/bin/helm \
    && ln -s /usr/local/bin/helm /usr/local/bin/h \
    && rm -rf helm-${HELM_VERSION}-linux-amd64.tar.gz linux-amd64 \
    && helm version

# Install hcloud CLI using the ARG value
RUN curl -L https://github.com/hetznercloud/cli/releases/download/${HCLOUD_VERSION}/hcloud-linux-amd64.tar.gz | tar -xz -C /usr/local/bin \
    && chmod +x /usr/local/bin/hcloud \
    && hcloud version

# Install Civo CLI
RUN curl -sL https://github.com/civo/cli/releases/download/v${CIVO_VERSION}/civo-${CIVO_VERSION}-linux-amd64.tar.gz | tar -xz -C /tmp \
    && mv /tmp/civo /usr/local/bin/ \
    && chmod +x /usr/local/bin/civo \
    && civo version

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && az --version

# Install Alibaba Cloud CLI
RUN curl -sL https://aliyuncli.alicdn.com/aliyun-cli-linux-${ALIYUN_VERSION}-amd64.tgz | tar -xz -C /tmp \
    && mv /tmp/aliyun /usr/local/bin/ \
    && chmod +x /usr/local/bin/aliyun \
    && aliyun --version

# Install specific versions of Terraform and Terragrunt
RUN tfenv install ${TERRAFORM_VERSION} \
    && tfenv use ${TERRAFORM_VERSION} \
    && tgenv install ${TERRAGRUNT_VERSION} \
    && terraform --version \
    && terragrunt --version

RUN groupadd user && groupadd guide \
    && useradd -m -u ${USER_ID} -g user -G guide -s /bin/bash user

WORKDIR /
RUN rm -rf /tmp/downloads

RUN echo 'echo "Shortcut aliases available: k (kubectl), h (helm)"' >> /etc/bash.bashrc \
    && echo 'echo "Cloud CLIs available: aws, gcloud, hcloud, civo, az, aliyun"' >> /etc/bash.bashrc

CMD ["/bin/bash"]