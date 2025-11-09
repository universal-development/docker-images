FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Node.js and npm
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Create user with UID/GID 1000:1000
# Ubuntu 24.04 may have existing user/group with UID/GID 1000
RUN existing_user=$(getent passwd 1000 | cut -d: -f1) && \
    if [ -n "$existing_user" ]; then \
        usermod -l user -d /home/user -m "$existing_user" 2>/dev/null || true; \
        groupmod -n user $(getent group 1000 | cut -d: -f1) 2>/dev/null || true; \
    else \
        groupadd -g 1000 user && useradd -u 1000 -g 1000 -m -s /bin/bash user; \
    fi

# Install AI CLI tools globally
RUN npm install -g @openai/codex && \
    npm install -g @anthropic-ai/claude-code && \
    npm install -g @github/copilot

# Switch to user
USER user
WORKDIR /home/user

CMD ["/bin/bash"]
