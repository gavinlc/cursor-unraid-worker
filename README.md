# cursor-unraid-worker

Always-on [Cursor My Machines](https://cursor.com/docs/cloud-agent/self-hosted/my-machines) worker for **Unraid**.

The agent loop runs in Cursor’s cloud; terminal/file tools run inside this container over **outbound HTTPS** only (no inbound ports).

**Primary path:** Unraid **Docker → Add Container** with the published image  
`ghcr.io/gavinlc/cursor-unraid-worker:latest`  
(Compose is optional — see [Build from source](#build-from-source-compose) below.)

> **First-time GHCR note:** Until the first GitHub Actions **Publish GHCR image** run succeeds, the image tag may not exist yet. After it publishes, open [Packages](https://github.com/gavinlc/cursor-unraid-worker/pkgs/container/cursor-unraid-worker) and set the package visibility to **Public** if Unraid cannot pull without a GitHub login.

---

## Unraid: Add Container (recommended)

### 1. Create host paths

On the Unraid host (SSH or Terminal):

```bash
mkdir -p /mnt/user/appdata/cursor-worker/{repo,config}
```

Optionally clone your project into the repo path now, or leave it empty and set `REPO_URL` so the container clones on first start.

### 2. Open Add Container

1. Unraid UI → **Docker**
2. **Add Container**

### 3. Choose the template

**Option A — manual (no template file)**

1. Leave **Template** blank / custom.
2. Set **Name:** `cursor-worker`
3. Set **Repository:** `ghcr.io/gavinlc/cursor-unraid-worker:latest`
4. Add path and variable **Configs** to match the [Unraid template XML](unraid/my-cursor-worker.xml) (see step 4).

**Option B — User Templates (drop-in XML)**

1. Copy [`unraid/my-cursor-worker.xml`](unraid/my-cursor-worker.xml) to:
   ```text
   /boot/config/plugins/dockerMan/templates-user/my-cursor-worker.xml
   ```
2. Or add a **Template Repositories** URL pointing at this repo’s templates if you maintain one.
3. Docker → Add Container → select **cursor-worker** / **my-cursor-worker** from **User Templates**.
4. Confirm **Repository** is `ghcr.io/gavinlc/cursor-unraid-worker:latest`.

### 4. Env + path mappings (match the XML)

| Config | Type | Container path / env | Host / value |
|--------|------|----------------------|--------------|
| Host Path repo | Path | `/workspace/repo` | `/mnt/user/appdata/cursor-worker/repo` (rw) |
| Host Path config | Path | `/home/cursor/.config/cursor-worker` | `/mnt/user/appdata/cursor-worker/config` (rw) |
| `CURSOR_API_KEY` | Variable | `CURSOR_API_KEY` | Personal key from [Dashboard → API Keys](https://cursor.com/dashboard) (or leave blank if using a token file) |
| `WORKER_NAME` | Variable | `WORKER_NAME` | `unraid` (name under My Machines) |
| `REPO_URL` | Variable | `REPO_URL` | Optional git remote to clone if repo path is empty |
| `REPO_BRANCH` | Variable | `REPO_BRANCH` | Optional (advanced) |
| `IDLE_RELEASE_TIMEOUT` | Variable | `IDLE_RELEASE_TIMEOUT` | `0` = stay connected (advanced) |
| `HTTPS_PROXY` | Variable | `HTTPS_PROXY` | Optional proxy URL (advanced) |

**Auth:** Use a **personal** Cursor user API key, not a team/service key.  
Alternatively write the key to `/mnt/user/appdata/cursor-worker/config/token` (`chmod 600`) and leave `CURSOR_API_KEY` empty.

Network: **bridge**. No ports to publish.

### 5. Apply → My Machines

1. Click **Apply** and wait for the container to start (pull may take a minute the first time).
2. Check logs: Docker → `cursor-worker` → **Logs**.
3. In [cursor.com/agents](https://cursor.com/agents) (same Cursor account), open the run location menu → **My Machines** → **unraid** (or your `WORKER_NAME`).

---

## Build from source (Compose)

Use this if you want to build locally instead of pulling GHCR.

1. Install **Docker Compose Manager** (Community Apps) if needed.
2. Clone this repo onto the array, e.g. `/mnt/user/appdata/cursor-unraid-worker`.
3. Create the same host dirs as above.
4. Copy env and set a personal API key:
   ```bash
   cp .env.example .env
   nano .env
   ```
5. From the repo directory:
   ```bash
   docker compose up -d --build
   docker compose logs -f cursor-worker
   ```

Useful commands:

```bash
docker compose ps
docker compose restart cursor-worker
docker compose down
```

---

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
docker exec -it cursor-worker agent worker debug
# or with Compose:
docker compose exec cursor-worker agent worker debug
```

- **Cannot pull image:** confirm the GHCR Actions workflow has succeeded and the package is **Public** (or configure a GHCR login on Unraid).
- Machine missing in picker: confirm the process is up, same Cursor account, and the repo volume has the expected git remote.
- Auth errors: use a **personal user** API key, not a team/service account key.
- Permission denied on Unraid shares: image runs as uid `99` (nobody). Adjust share ownership or run as a matching PUID.
