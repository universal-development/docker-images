FROM ubuntu:22.04

RUN apt-get -y update && apt-get -y install ssh git curl wget unzip && apt-get clean

RUN git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
RUN git clone https://github.com/cunymatthieu/tgenv.git ~/.tgenv

ENV PATH="/root/.tgenv/bin:/root/.tfenv/bin:$PATH"

RUN tfenv install v1.4.6
RUN tfenv use v1.4.6  
RUN tgenv install 0.45.8

