FROM ubuntu:22.04

# Avoid prompts from apt during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update apt package lists
RUN apt-get update && apt-get install -y \
    ssh \
    rsync \
    unzip \
    curl \
    wget \
    jq \
    p7zip-full \
    bzip2 \
    && rm -rf /var/lib/apt/lists/*

# Set specific versions
ENV RCLONE="1.68.1"
ENV RESTIC="0.16.4"
ENV MINIO_CLIENT="RELEASE.2024-03-15T01-07-19Z"

# Download and install Rclone specific version
RUN curl -L https://github.com/rclone/rclone/releases/download/v${RCLONE}/rclone-v${RCLONE}-linux-amd64.deb -o rclone.deb \
    && dpkg -i rclone.deb \
    && rm rclone.deb

# Download and install Restic specific version
RUN curl -L https://github.com/restic/restic/releases/download/v${RESTIC}/restic_${RESTIC}_linux_amd64.bz2 -o restic.bz2 \
    && bzip2 -d restic.bz2 \
    && chmod +x restic \
    && mv restic /usr/local/bin/

# Download and install MinIO Client specific version
RUN curl -L https://dl.min.io/client/mc/release/linux-amd64/archive/mc.${MINIO_CLIENT} -o mc \
    && chmod +x mc \
    && mv mc /usr/local/bin/

# Download and install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip ./aws

# Verify installation
RUN aws --version
