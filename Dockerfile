FROM python:3.11

# Download precompiled ttyd binary from GitHub releases
RUN apt-get update && \
    apt-get install -y wget net-tools lsof && \
    wget https://github.com/tsl0922/ttyd/releases/download/1.6.3/ttyd.x86_64 -O /usr/bin/ttyd && \
    chmod +x /usr/bin/ttyd && \
    apt-get remove -y wget && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

ENV NVM_DIR /root/.nvm

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install node \
    && nvm use node

# Install Latest Go
RUN ARCHITECTURE=$(uname -m) && \
    if [ "$ARCHITECTURE" = "x86_64" ]; then \
    GOARCH="amd64"; \
    elif [ "$ARCHITECTURE" = "aarch64" ]; then \
    GOARCH="arm64"; \
    else \
    exit 1; \
    fi && \
    GOLANG_VERSION=$(curl -L -sS -A "Mozilla/5.0" "https://go.dev/VERSION?m=text" | awk 'NR==1{print $1}') && \
    echo "Detected version: $GOLANG_VERSION" && \
    DOWNLOAD_URL="https://dl.google.com/go/${GOLANG_VERSION}.linux-${GOARCH}.tar.gz" && \
    echo "Download URL: $DOWNLOAD_URL" && \
    curl -o go.tgz -A "Mozilla/5.0" "$DOWNLOAD_URL" && \
    tar -C /usr/local -xzf go.tgz && \
    rm go.tgz
ENV PATH $PATH:/usr/local/go/bin

WORKDIR /usr/src/app
COPY . .
RUN pip install --no-cache-dir -r requirements.txt
RUN python -m venv pilot-env
RUN /bin/bash -c "source pilot-env/bin/activate"

RUN pip install -r requirements.txt
WORKDIR /usr/src/app/pilot

EXPOSE 7681
CMD ["ttyd", "bash"]