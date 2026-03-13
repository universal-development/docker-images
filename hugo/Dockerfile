# syntax=docker/dockerfile:1
FROM ubuntu:24.04

# Install base packages including Python
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    jq \
    wget \
    vim \
    less \
    rclone \
    restic \
    gettext-base \
    mc \
    sudo \
    python3 \
    python3-pip \
    python3-venv \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Go
ENV GO_VERSION=1.25.5
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:${PATH}"

# Install Node.js LTS
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PostCSS and Autoprefixer globally (required by Hugo themes for CSS processing)
RUN npm install -g postcss-cli autoprefixer

# Install Hugo extended
ENV HUGO_VERSION=0.154.5
RUN wget -qO- https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz | tar -xz -C /usr/local/bin hugo

# Install Pagefind
ENV PAGEFIND_VERSION=1.4.0
RUN wget -qO- https://github.com/CloudCannon/pagefind/releases/download/v${PAGEFIND_VERSION}/pagefind-v${PAGEFIND_VERSION}-x86_64-unknown-linux-musl.tar.gz | tar -xz -C /usr/local/bin

# Set working directory
WORKDIR /workspace

# Set default command
CMD ["/bin/bash"]
