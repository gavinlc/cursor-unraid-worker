#!/usr/bin/env bash
set -euo pipefail

WORKER_NAME="${WORKER_NAME:-unraid}"
WORKER_DIR="${WORKER_DIR:-/workspace/repo}"
IDLE_RELEASE_TIMEOUT="${IDLE_RELEASE_TIMEOUT:-0}"
REPO_URL="${REPO_URL:-}"
REPO_BRANCH="${REPO_BRANCH:-}"
AUTH_TOKEN_FILE="${AUTH_TOKEN_FILE:-/home/cursor/.config/cursor-worker/token}"

mkdir -p "$(dirname "$AUTH_TOKEN_FILE")" "$WORKER_DIR"

log() { printf '[cursor-worker] %s\n' "$*"; }

# Optional: seed / update a git checkout when REPO_URL is set
if [[ -n "$REPO_URL" ]]; then
  if [[ ! -d "$WORKER_DIR/.git" ]]; then
    log "Cloning $REPO_URL into $WORKER_DIR"
    # Parent may already exist as an empty volume mount
    if [[ -z "$(ls -A "$WORKER_DIR" 2>/dev/null || true)" ]]; then
      git clone "$REPO_URL" "$WORKER_DIR"
    else
      log "WORKER_DIR is not empty and has no .git — skipping clone. Mount a checkout or clear the volume."
    fi
  else
    log "Fetching updates in $WORKER_DIR"
    git -C "$WORKER_DIR" fetch --all --prune || true
  fi
  if [[ -n "$REPO_BRANCH" && -d "$WORKER_DIR/.git" ]]; then
    git -C "$WORKER_DIR" checkout "$REPO_BRANCH" || true
    git -C "$WORKER_DIR" pull --ff-only || true
  fi
fi

if [[ ! -d "$WORKER_DIR" ]]; then
  log "ERROR: WORKER_DIR does not exist: $WORKER_DIR"
  exit 1
fi

ARGS=(worker start --name "$WORKER_NAME" --worker-dir "$WORKER_DIR" --idle-release-timeout "$IDLE_RELEASE_TIMEOUT")

# Prefer token file (Unraid-friendly). Fall back to CURSOR_API_KEY env.
if [[ -f "$AUTH_TOKEN_FILE" && -s "$AUTH_TOKEN_FILE" ]]; then
  log "Using auth token file: $AUTH_TOKEN_FILE"
  ARGS+=(--auth-token-file "$AUTH_TOKEN_FILE")
elif [[ -n "${CURSOR_API_KEY:-}" ]]; then
  log "Using CURSOR_API_KEY from environment"
  ARGS+=(--api-key "$CURSOR_API_KEY")
else
  log "ERROR: No credentials. Set CURSOR_API_KEY or mount a personal token at $AUTH_TOKEN_FILE"
  log "Create a personal API key: Cursor Dashboard → API Keys (user key, not team/service)."
  exit 1
fi

log "Starting: agent ${ARGS[*]}"
exec agent "${ARGS[@]}"
