FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive


RUN apt-get -y update \
  && apt-get -y install wget \
     rdesktop remmina mate-desktop-environment-extras

RUN apt-get clean
