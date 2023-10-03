FROM universaldevelopment/base-generic:22.04

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get install -y --no-install-recommends tzdata ssh telnet mc wget curl && apt-get clean
WORKDIR /tmp
RUN wget https://download.java.net/java/GA/jdk21/fd2272bbf8e04c3dbaee13770090416c/35/GPL/openjdk-21_linux-x64_bin.tar.gz
RUN tar xfvz openjdk-21_linux-x64_bin.tar.gz
RUN rm openjdk-21_linux-x64_bin.tar.gz
RUN mv jdk-21 /opt/
RUN ln -s /opt/jdk-21/bin/java /usr/bin/java 
RUN ln -s /opt/jdk-21/bin/javac /usr/bin/javac
