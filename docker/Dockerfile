FROM coderluii/holyclaude:latest

USER root

ARG DEBIAN_FRONTEND=noninteractive
ARG ROCK_INSTALL_AGY=0
ARG ROCK_AGY_INSTALL_COMMAND="curl -fsSL https://antigravity.google/cli/install.sh | bash"

ENV TZ=America/Toronto \
    R_LIBS_USER=/home/claude/R/library \
    NPM_CONFIG_PREFIX=/home/claude/.local \
    PATH=/home/claude/.local/bin:$PATH \
    ROCK_INSTALL_AGY=${ROCK_INSTALL_AGY} \
    ROCK_AGY_INSTALL_COMMAND=${ROCK_AGY_INSTALL_COMMAND}

# Use CRAN apt repo for current R. Ubuntu and Debian CRAN repos use different signing keys:
# Ubuntu: marutter_pubkey.asc from cloud.r-project.org
# Debian: key B8F25A8A73EACF41 from keyserver.ubuntu.com (Debian CRAN maintainer key)
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    dirmngr \
    gnupg \
    ca-certificates \
    wget \
    && . /etc/os-release \
    && if [ "$ID" = "ubuntu" ]; then \
         wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc \
             | gpg --dearmor -o /usr/share/keyrings/cran-archive-keyring.gpg; \
         CRAN_CODENAME="${UBUNTU_CODENAME:-noble}"; \
       else \
         wget -qO- "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xB8F25A8A73EACF41" \
             | gpg --dearmor -o /usr/share/keyrings/cran-archive-keyring.gpg; \
         CRAN_CODENAME="${VERSION_CODENAME:-bookworm}"; \
       fi \
    && echo "deb [signed-by=/usr/share/keyrings/cran-archive-keyring.gpg] https://cloud.r-project.org/bin/linux/${ID:-ubuntu} ${CRAN_CODENAME}-cran40/" \
         > /etc/apt/sources.list.d/cran-r.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    r-base \
    r-base-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libuv1-dev \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/claude/R/library /home/claude/.local /work/proposed /work/scratch /opt/rock/skills \
    && chown -R claude:claude /home/claude/R /home/claude/.local /work /opt/rock

COPY docker/install-r-packages.R /tmp/install-r-packages.R
RUN Rscript /tmp/install-r-packages.R && rm /tmp/install-r-packages.R

COPY docker/install-extra-agents.sh /usr/local/bin/install-extra-agents.sh
COPY docker/update-agent-clis.sh /usr/local/bin/rock-update-agent-clis
COPY docker/rock-preflight.sh /usr/local/bin/rock-preflight
COPY docker/rock-summary.sh /usr/local/bin/rock-summary
RUN chmod +x /usr/local/bin/rock-update-agent-clis \
             /usr/local/bin/rock-preflight \
             /usr/local/bin/rock-summary \
    && /usr/local/bin/install-extra-agents.sh

WORKDIR /workspace
