FROM ubuntu:22.04

# Install openssh-server and prepare sshd
RUN apt-get update && \
    apt-get install -y openssh-server && \
    mkdir /var/run/sshd

# Copy entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Update sshd_config to allow root login and password authentication at build
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

EXPOSE 22

ENTRYPOINT ["/docker-entrypoint.sh"]
