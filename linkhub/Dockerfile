FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update \
  && apt-get -y install wget mc screen \
    openssh-client \
    telnet \
    ftp lftp rsync tar rclone \
    curl \
    rdesktop remmina mate-desktop-environment-extras freerdp2-x11 \
    sudo

RUN curl -1sLf 'https://dl.cloudsmith.io/public/asbru-cm/release/cfg/setup/bash.deb.sh' | sudo -E bash
RUN apt-get install -y asbru-cm

