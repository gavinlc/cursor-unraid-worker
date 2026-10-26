# Cursor My Machines worker image for Unraid / Docker Compose.
# Docs: https://cursor.com/docs/cloud-agent/self-hosted/my-machines
#
# Baseline for ai-job-search /scrape /rank /apply (Bun portal CLIs, Python tools,
# lualatex/xelatex CV+cover compile, Poppler ATS/layout checks). No secrets baked in.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    HOME=/home/cursor

# System + workflow deps as root (TeX set matches ai-job-search .cursor/cloud-agent-install.sh)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        openssh-client \
        passwd \
        bash \
        tini \
        unzip \
        xz-utils \
        fontconfig \
        python3 \
        python3-pip \
        python3-venv \
        python3-yaml \
        python3-openpyxl \
        python3-pypdf \
        poppler-utils \
        texlive-luatex \
        texlive-xetex \
        texlive-latex-recommended \
        texlive-latex-extra \
        texlive-fonts-recommended \
        texlive-fonts-extra \
    && rm -rf /var/lib/apt/lists/* \
    && /usr/sbin/useradd --create-home --shell /bin/bash --uid 99 cursor

# Unraid often maps containers as nobody (99:100). uid 99 matches "nobody" on many Unraid hosts.
USER cursor
WORKDIR /home/cursor
# PATH: Cursor agent, Bun, then system TeX/Python. Set after USER so build still finds /usr/sbin when needed.
ENV PATH=/home/cursor/.local/bin:/home/cursor/.bun/bin:/usr/local/bin:/usr/bin:/bin \
    BUN_INSTALL=/home/cursor/.bun

# Install Cursor CLI + Bun as the runtime user (no sudo in image)
RUN curl -fsSL https://cursor.com/install | bash \
    && command -v agent \
    && agent --version \
    && curl -fsSL https://bun.sh/install | bash \
    && command -v bun \
    && bun --version \
    && command -v lualatex \
    && command -v xelatex \
    && command -v pdftotext \
    && python3 --version \
    && python3 -c "import yaml, pypdf, openpyxl"

COPY --chown=cursor:cursor entrypoint.sh /home/cursor/entrypoint.sh
RUN chmod +x /home/cursor/entrypoint.sh

# Persistent mounts (declared for documentation; Compose binds them)
VOLUME ["/workspace/repo", "/home/cursor/.config/cursor-worker"]

ENTRYPOINT ["/usr/bin/tini", "--", "/home/cursor/entrypoint.sh"]
