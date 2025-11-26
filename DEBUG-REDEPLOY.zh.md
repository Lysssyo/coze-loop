# 本地调试版重新部署指南（WSL）

说明：使用 debug 配置在 WSL 内重建 app 镜像并启动全套容器。debug 入口使用 dlv，需要手动 continue 才能通过健康检查并启动 nginx。

## 前置条件
- WSL 内可用 Docker（`docker compose version` 正常）。
- 仓库路径（WSL）：`/mnt/d/AAA_SecondDesktop/A_Technology/golang/coze-loop`。
- RocketMQ namesrv 可用，域名 `coze-loop-rmq-namesrv:9876`（compose 默认网络）。

## 1) 修正 observability 配置（避免 panic）
编辑 `release/deployment/docker-compose/conf/observability.yaml`，确保存在且填写：

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
其他 trace 相关 topic/addr 也应指向 `coze-loop-rmq-namesrv:9876`，且 topic 不能为空。

## 2) 构建 app（仅 debug 镜像）
```bash
cd /mnt/d/AAA_SecondDesktop/A_Technology/golang/coze-loop
docker compose \
  -f release/deployment/docker-compose/docker-compose.yml \
  -f release/deployment/docker-compose/docker-compose-debug.yml \
  --env-file release/deployment/docker-compose/.env \
  --profile "*" \
  build app
```

## 3) 启动容器
全量启动：
```bash
docker compose \
  -f release/deployment/docker-compose/docker-compose.yml \
  -f release/deployment/docker-compose/docker-compose-debug.yml \
  --env-file release/deployment/docker-compose/.env \
  --profile "*" \
  up -d
```

仅刷新 app（不动其他服务）：
```bash
docker compose \
  -f release/deployment/docker-compose/docker-compose.yml \
  -f release/deployment/docker-compose/docker-compose-debug.yml \
  --env-file release/deployment/docker-compose/.env \
  --profile "*" \
  up -d --build --force-recreate --no-deps app
```

## 4) 通过 dlv 继续运行（健康检查/ nginx 必需）
debug 入口是 `dlv --headless`，默认等待。运行：
```bash
printf 'continue\nexit\n' | docker exec -i coze-loop-app dlv connect :40000 --api-version=2
```
或 IDE/CLI 远程调试：连 `localhost:40000`（API v2），点击 Resume/Continue。

## 5) 验证
```bash
docker compose \
  -f release/deployment/docker-compose/docker-compose.yml \
  -f release/deployment/docker-compose/docker-compose-debug.yml \
  --env-file release/deployment/docker-compose/.env \
  --profile "*" \
  ps
```
预期 `coze-loop-app`、`coze-loop-nginx` 均为 `healthy`。

访问：
- App: http://localhost:8888/ping
- Nginx: http://localhost:8082

## 6) 备注 / 排查
- 如遇 RocketMQ 报 producer/consumer group 冲突，可改成唯一组名。
- 健康检查若一直 `starting`，先确认已执行 dlv continue；若仍失败，看 `docker compose ... logs app`。
- 停止：同样的 compose 文件使用 `down` 或 `down -v`（谨慎清理卷）。
