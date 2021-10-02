FROM denis256/base-generic:0.0.2

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get install -y --no-install-recommends tzdata ssh telnet mc wget curl && apt-get clean
WORKDIR /tmp
RUN wget https://download.java.net/openjdk/jdk17/ri/openjdk-17+35_linux-x64_bin.tar.gz
RUN tar xfvz openjdk-17+35_linux-x64_bin.tar.gz
RUN rm openjdk-17+35_linux-x64_bin.tar.gz
RUN mv jdk-17 /opt/
RUN ln -s /opt/jdk-17/bin/java /usr/bin/java 
RUN ln -s /opt/jdk-17/bin/javac /usr/bin/javac