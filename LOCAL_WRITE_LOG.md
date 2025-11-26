# Local Dev Write Log

- Added dev proxy to `frontend/apps/cozeloop/rsbuild.config.ts`: `server.proxy` now routes `/api` to `http://localhost:8888` for local backend during `rushx dev`.
- Added `local-dev.bat`: sets required Coze Loop env vars, starts backend via `go run backend\cmd` (working dir `release\deployment\docker-compose`, `PWD` set for config loader), and starts frontend via `rushx dev`. Assumes WSL Docker Compose stack (redis/mysql/clickhouse/minio/rocketmq/faas) already running and port-forwarded to Windows.
- Updated 'local-dev.bat' to clean up the env var chain separators (avoid extra && between ClickHouse env vars).

- Added Go version guard (>=1.24.x 64-bit) to local-dev.bat; script now exits early with guidance if Go is missing or too old.

- Updated local-dev.bat error paths to pause before exit so messages stay visible when Go is missing/too old.

- Updated local-dev.bat to prefer 64-bit Go at C:\Program Files\Go\bin, and to warn/pause if GOARCH=386.

- Added end-of-script pause and reminder messages to keep window open after spawning backend/frontend.

- Updated backend/conf/infrastructure.yaml for local dev (127.0.0.1 services, idgen.server_ids=[1], minio/clickhouse/mysql/redis endpoints) to avoid idgen init panic.

- Copied release/deployment/docker-compose/conf/model_config.yaml to backend/conf/model_config.yaml for local backend config resolution.

- Copied model_runtime_config.yaml from release/deployment/docker-compose/conf to backend/conf for local backend run.

- Synced all *.yaml from release/deployment/docker-compose/conf to backend/conf to satisfy local backend config loading.

- Added BACKEND_LOCAL_START.md summarizing end-to-end local backend start steps, PATH/env rationale, and config copy reasons.

- Added FRONTEND_LOCAL_START.md documenting complete local frontend start steps, proxy mapping, and rush usage via install-run-rush* scripts.

- Updated FRONTEND_LOCAL_START.md with Windows long-path build error workaround (set RUSH_TEMP_FOLDER / RUSH_PNPM_STORE_PATH or move repo to shorter path).

- Updated FRONTEND_LOCAL_START.md: avoid RUSH_TEMP_FOLDER with workspaces; recommend only RUSH_PNPM_STORE_PATH for shortening paths.

