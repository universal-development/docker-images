FROM centos:8

RUN dnf -y install epel-release
RUN dnf -y install which nfs-utils rsync openssh-clients sshpass httpd-tools wget unzip

RUN dnf -y install python3-pip

RUN dnf -y makecache
RUN dnf -y install ansible

RUN mkdir /tmp/downloads

WORKDIR /tmp/downloads
# Download terraform
RUN wget https://releases.hashicorp.com/terraform/1.1.3/terraform_1.1.3_linux_amd64.zip

RUN unzip terraform_1.1.3_linux_amd64.zip
RUN mv terraform /usr/local/bin/
RUN terraform --version 

# Download terragrunt
RUN wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.35.16/terragrunt_linux_amd64 -O /usr/bin/terragrunt
RUN chmod +x /usr/bin/terragrunt

RUN pip3 --no-cache-dir install --upgrade awscli

RUN dnf -y install git curl

RUN wget https://dl.k8s.io/release/v1.23.0/bin/linux/amd64/kubectl -O /usr/bin/kubectl
RUN chmod +x /usr/bin/kubectl

RUN wget https://get.helm.sh/helm-v3.7.2-linux-amd64.tar.gz
RUN tar xfvz helm-v3.7.2-linux-amd64.tar.gz
RUN mv linux-amd64/helm /usr/local/bin/helm

WORKDIR /
RUN rm -rf /tmp/downloads

ADD run-ansible-playbook /usr/bin/run-ansible-playbook
