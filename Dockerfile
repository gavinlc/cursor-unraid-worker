# Cursor My Machines worker image for Unraid / Docker Compose.
# Docs: https://cursor.com/docs/cloud-agent/self-hosted/my-machines
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    HOME=/home/cursor \
    PATH=/home/cursor/.local/bin:/usr/local/bin:/usr/bin:/bin

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        openssh-client \
        passwd \
        python3 \
        bash \
        tini \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --shell /bin/bash --uid 99 cursor

# Unraid often maps containers as nobody (99:100). uid 99 matches "nobody" on many Unraid hosts.
USER cursor
WORKDIR /home/cursor

# Install Cursor CLI as the runtime user
RUN curl -fsSL https://cursor.com/install | bash \
    && command -v agent \
    && agent --version

COPY --chown=cursor:cursor entrypoint.sh /home/cursor/entrypoint.sh
RUN chmod +x /home/cursor/entrypoint.sh

# Persistent mounts (declared for documentation; Compose binds them)
VOLUME ["/workspace/repo", "/home/cursor/.config/cursor-worker"]

ENTRYPOINT ["/usr/bin/tini", "--", "/home/cursor/entrypoint.sh"]
