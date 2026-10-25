# cursor-unraid-worker

Always-on [Cursor My Machines](https://cursor.com/docs/cloud-agent/self-hosted/my-machines) worker for **Unraid** (Docker Compose).

The agent loop runs in Cursor’s cloud; terminal/file tools run inside this container over **outbound HTTPS** only (no inbound ports).

## Unraid setup (Compose Manager)

1. Install **Docker Compose Manager** (Community Apps) if you don’t have it.
2. Clone or copy this folder onto the array, e.g. `/mnt/user/appdata/cursor-unraid-worker`.
3. Create host dirs:
   ```bash
   mkdir -p /mnt/user/appdata/cursor-worker/{repo,config}
   ```
4. Either:
   - `git clone` your project into `.../cursor-worker/repo`, or
   - set `REPO_URL` in `.env` and let the container clone on first start.
5. Copy env and add a **personal** API key from [Cursor Dashboard → API Keys](https://cursor.com/dashboard):
   ```bash
   cp .env.example .env
   nano .env   # set CURSOR_API_KEY, REPO_URL, paths
   ```
   Or write the key to `/mnt/user/appdata/cursor-worker/config/token` (chmod 600) and leave `CURSOR_API_KEY` empty.
6. From this directory:
   ```bash
   docker compose up -d --build
   docker compose logs -f cursor-worker
   ```
7. In [cursor.com/agents](https://cursor.com/agents) (same Cursor account), open the run location menu → **My Machines** → **unraid** (or your `WORKER_NAME`).

## Useful compose commands

```bash
docker compose ps
docker compose restart cursor-worker
docker compose down
```

## Notes for ai-job-search

- Mount a checkout that includes **personal** files (`CLAUDE.md`, tracker, CVs). Those are gitignored upstream — clone alone is not enough for `/apply`.
- Prefer Origin remotes for agent branches if that is your Project preference; set `REPO_URL` accordingly.
- Cloud Agent environments stay useful for clean builds without personal data; this Unraid worker is for long-lived local state.

## Networking

Allow outbound HTTPS to at least:

- `api2.cursor.sh` / `api2direct.cursor.sh`
- `downloads.cursor.com`
- artifact hosts listed in the [My Machines networking docs](https://cursor.com/docs/cloud-agent/self-hosted/my-machines)

## Troubleshooting

```bash
docker compose exec cursor-worker agent worker debug
```

- Machine missing in picker: confirm the process is up, same Cursor account, and `WORKER_DIR` has the expected git remote.
- Auth errors: use a **personal user** API key, not a team/service account key.
- Permission denied on Unraid shares: image runs as uid `99` (nobody). Adjust share ownership or run as a matching PUID.
