# 本地启动后端（Windows + WSL 依赖）操作指引

> 目标：依赖留在 WSL Docker Compose，中控前后端本地直启，方便调试。

## 0. 依赖服务（在 WSL 内）

```bash
cd /mnt/d/AAA_SecondDesktop/A_Technology/golang/coze-loop/release/deployment/docker-compose
docker compose -f docker-compose.yml -f docker-compose-local.yml --env-file .env \
  --profile redis --profile mysql --profile clickhouse --profile minio --profile rmq --profile faas up -d
docker compose ps   # 确认 redis/mysql/clickhouse/minio/rocketmq/faas Healthy
```

确保端口可达（在 Windows PowerShell 可选执行）：
```powershell
Test-NetConnection 180.184.27.188 -Port 3306  # 期待 TcpTestSucceeded=True
```

## 1. 后端本地启动（PowerShell）

```powershell
# 1) 工作目录设置为 conf 所在路径，便于后端读取配置
 cd D:\coze-loop\release\deployment\docker-compose

$env:PWD = (Get-Location).Path

# 2) 将 64 位 Go 放在 PATH 最前，避免旧版本/32 位被使用
$env:PATH = "C:\Program Files\Go\bin;$env:PATH"

# 3) 端口映射环境变量（对应 WSL Compose 的端口暴露）
$env:COZE_LOOP_REDIS_DOMAIN="180.184.27.188";  $env:COZE_LOOP_REDIS_PORT="6379";  $env:COZE_LOOP_REDIS_PASSWORD="cozeloop-redis"
$env:COZE_LOOP_MYSQL_DOMAIN="180.184.27.188";  $env:COZE_LOOP_MYSQL_PORT="3306";  $env:COZE_LOOP_MYSQL_USER="root";  $env:COZE_LOOP_MYSQL_PASSWORD="cozeloop-mysql";  $env:COZE_LOOP_MYSQL_DATABASE="cozeloop-mysql"
$env:COZE_LOOP_CLICKHOUSE_DOMAIN="180.184.27.188";  $env:COZE_LOOP_CLICKHOUSE_PORT="9000";  $env:COZE_LOOP_CLICKHOUSE_USER="default";  $env:COZE_LOOP_CLICKHOUSE_PASSWORD="cozeloop-clickhouse";  $env:COZE_LOOP_CLICKHOUSE_DATABASE="cozeloop-clickhouse"
$env:COZE_LOOP_OSS_PROTOCOL="http";  $env:COZE_LOOP_OSS_DOMAIN="180.184.27.188";  $env:COZE_LOOP_OSS_PORT="9001";  $env:COZE_LOOP_OSS_REGION="us-east-1";  $env:COZE_LOOP_OSS_USER="root";  $env:COZE_LOOP_OSS_PASSWORD="cozeloop-minio";  $env:COZE_LOOP_OSS_BUCKET="cozeloop-minio"
$env:COZE_LOOP_RMQ_NAMESRV_DOMAIN="180.184.27.188";  $env:COZE_LOOP_RMQ_NAMESRV_PORT="9876"
$env:COZE_LOOP_PYTHON_FAAS_DOMAIN="180.184.27.188";  $env:COZE_LOOP_PYTHON_FAAS_PORT="8000"
$env:COZE_LOOP_JS_FAAS_DOMAIN="180.184.27.188";  $env:COZE_LOOP_JS_FAAS_PORT="8001"

# 4) 进入 backend 模块（有 go.mod）
 cd D:\coze-loop\backend

# 5)（可选）设置 Go 代理，加速依赖

# 6) 启动后端
go run .\cmd
```

启动成功后，可在另一窗口验证：
```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8888/ping
```

## 2. 为什么要复制 conf/*.yaml 到 backend/conf？

后端启动时会在自身 `backend/conf` 下寻找 `infrastructure.yaml`、`model_config.yaml`、`model_runtime_config.yaml`、`prompt.yaml` 等配置。为了让本地直启与 Compose 配置保持一致，已将 `release/deployment/docker-compose/conf/*.yaml` 同步到 `backend/conf/`。这样：
- `idgen.server_ids` 不为空（避免 panic）
- 模型、运行时、提示词配置与 Compose 版本一致

## 3. PATH 调整的原因

机器上存在旧版或 32 位 Go 时，会被默认选中导致编译/运行失败。`$env:PATH = "C:\Program Files\Go\bin;$env:PATH"` 将 64 位 Go 1.24.x 放到 PATH 最前，确保 `go run` 使用正确版本。

## 4. 前端本地启动（备用）

```powershell
cd D:\AAA_SecondDesktop\A_Technology\golang\coze-loop\frontend\apps\cozeloop
rushx dev
```
前端已配置 `/api` 代理到 `http://localhost:8888`，直接连接本地后端。





› 我是问： 已将 model_runtime_config.yaml 复制到 backend/conf/model_runtime_config.yaml，这些是在干嘛


• 这些复制是为了解决后端本地直启时“找不到配置文件”的 panic：

  - 后端代码启动时，会在自身目录的 backend/conf 下寻找一系列配置文件（如 infrastructure.yaml、model_config.yaml、
    model_runtime_config.yaml、prompt.yaml 等）。默认这些文件只在容器用的路径 release/deployment/docker-compose/conf 下存在。
  - 本地直启时，如果 backend/conf 缺少这些文件，就会报 “file xxx not found” 或 idgen 初始化失败等 panic。
  - 所以把 release/deployment/docker-compose/conf/*.yaml 同步到 backend/conf/，让后端在本地运行时能加载到与容器一致的配置（模型、运行时、提
    示词、基础设施、idgen server_ids 等），从而顺利启动。

  这一步只是在补齐配置搜索路径，让本地运行和容器运行配置一致，不影响代码逻辑。
