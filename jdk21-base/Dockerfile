FROM universaldevelopment/base-generic:22.04

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get install -y --no-install-recommends tzdata ssh telnet mc wget curl && apt-get clean
WORKDIR /tmp
RUN wget https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_linux-x64_bin.tar.gz
RUN tar xfvz openjdk-21.0.2_linux-x64_bin.tar.gz
RUN rm openjdk-21.0.2_linux-x64_bin.tar.gz
RUN mv jdk-21.0.2 /opt/ && ln -s /opt/jdk-21.0.2 /opt/jdk-21
RUN ln -s /opt/jdk-21/bin/java /usr/bin/java 
RUN ln -s /opt/jdk-21/bin/javac /usr/bin/javac

RUN java -version
RUN javac -version
