FROM ubuntu:24.04

# Set envs
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV MMS_VERSION latest

RUN apt-get -qqy update \
 && apt-get -qqy upgrade \
 && apt-get -qqy install curl logrotate \
 && curl -sSL https://cloud.mongodb.com/download/agent/monitoring/mongodb-mms-monitoring-agent_${MMS_VERSION}_amd64.ubuntu1604.deb -o mms.deb \
 && dpkg -i mms.deb \
 && rm mms.deb \
 && apt-get -qqy autoremove \
 && apt-get -qqy clean \
 && rm -rf /var/lib/apt/*

CMD ["mongodb-mms-monitoring-agent", "--conf", "/mongodb-mms-monitoring.config"]
