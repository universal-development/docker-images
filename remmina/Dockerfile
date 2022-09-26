FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive


RUN apt-get -y update \
  && apt-get -y install wget \
     rdesktop remmina mate-desktop-environment-extras freerdp2-x11 

RUN apt-get clean
