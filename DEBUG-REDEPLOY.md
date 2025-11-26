# Local Debug Re-deploy Guide (WSL)

This doc shows how to rebuild the app image and run the full stack in containers with the debug profile on WSL. It also covers the dlv continue step that is required for the app health check to pass and for nginx to start.

## Prerequisites
- Docker available inside WSL (`docker compose version` works).
- Repository path in WSL: `/mnt/d/AAA_SecondDesktop/A_Technology/golang/coze-loop`.
- Network: RocketMQ namesrv reachable as `coze-loop-rmq-namesrv:9876` (default compose network).

## 1) Fix observability config (avoid panic)
Edit `release/deployment/docker-compose/conf/observability.yaml` and ensure the following blocks exist (addr points to namesrv, topic non-empty, unique producer/consumer groups):

```yaml
span_with_annotation_mq_producer_config:
  addr:
    - "coze-loop-rmq-namesrv:9876"
  timeout: 200
  retry_times: 3
  topic: "trace_annotation_event"
  producer_group: "trace_annotation_event_span_pg"

span_with_annotation_mq_consumer_config:
  addr:
    - "coze-loop-rmq-namesrv:9876"
  timeout: 180000
  topic: "trace_annotation_event"
  consumer_group: "trace_annotation_event_span_cg"
  worker_num: 4
```

## 2) Build the app (debug image only)
```bash
cd /mnt/d/AAA_SecondDesktop/A_Technology/golang/coze-loop
docker compose \
  -f release/deployment/docker-compose/docker-compose.yml \
  -f release/deployment/docker-compose/docker-compose-debug.yml \
  --env-file release/deployment/docker-compose/.env \
  --profile "*" \
  build app
```

## 3) Start containers
Full stack:
```bash
docker compose \
  -f release/deployment/docker-compose/docker-compose.yml \
  -f release/deployment/docker-compose/docker-compose-debug.yml \
  --env-file release/deployment/docker-compose/.env \
  --profile "*" \
  up -d
```

Only refresh app (keeps other services):
```bash
docker compose \
  -f release/deployment/docker-compose/docker-compose.yml \
  -f release/deployment/docker-compose/docker-compose-debug.yml \
  --env-file release/deployment/docker-compose/.env \
  --profile "*" \
  up -d --build --force-recreate --no-deps app
```

## 4) Resume app via dlv (required for healthcheck/nginx)
The debug entrypoint starts `dlv --headless` and waits. Run:
```bash
printf 'continue\nexit\n' | docker exec -i coze-loop-app dlv connect :40000 --api-version=2
```
Or attach with IDE/CLI to `localhost:40000` (API v2) and hit Resume/Continue.

## 5) Verify
```bash
docker compose \
  -f release/deployment/docker-compose/docker-compose.yml \
  -f release/deployment/docker-compose/docker-compose-debug.yml \
  --env-file release/deployment/docker-compose/.env \
  --profile "*" \
  ps
```
Expect `coze-loop-app` and `coze-loop-nginx` to be `healthy`.

Endpoints:
- App: http://localhost:8888/ping
- Nginx: http://localhost:8082

## 6) Notes / Troubleshooting
- If RocketMQ errors about producer/consumer groups, pick unique group names in the observability config.
- If healthcheck stays `starting`, ensure the dlv continue step ran; if still failing, check `docker compose ... logs app`.
- To stop everything: same compose files with `down` or `down -v` (be careful with volumes).
