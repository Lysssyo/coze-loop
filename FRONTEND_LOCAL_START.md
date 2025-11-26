# 本地启动前端（Windows）完整指引

> 目标：依赖服务在 WSL Docker Compose，中控前端本地直启，调试时 `/api` 直连本地后端 `http://localhost:8888`。

## 1. 准备前提

- Node 版本：使用 `.nvmrc` 指定的 LTS/iron（Node 20.x）。确保 `node -v` 显示 20.x。
- WSL 中 Docker Compose 依赖已启动并映射到宿主机：
  ```bash
  cd /mnt/d/AAA_SecondDesktop/A_Technology/golang/coze-loop/release/deployment/docker-compose
  docker compose -f docker-compose.yml -f docker-compose-local.yml --env-file .env \
    --profile redis --profile mysql --profile clickhouse --profile minio --profile rmq --profile faas up -d
  ```
  （`docker compose ps` 确认各服务 Healthy）
- 后端已本地启动（见 `BACKEND_LOCAL_START.md`），确保 `http://localhost:8888/ping` 可通。

## 2. 依赖安装（无须全局安装 Rush，使用仓库内脚本）

在仓库根目录执行：
```powershell
cd D:\AAA_SecondDesktop\A_Technology\golang\coze-loop
node .\common\scripts\install-run-rush.js install --to @cozeloop/community-base --ignore-hooks
```
说明：`install-run-rush.js` 是 Rush 官方提供的便捷脚本，会自动下载匹配版本（5.147.1）并执行 `rush install`，不需要管理员权限，也不污染全局。

## 3. 启动前端

```powershell
cd D:\AAA_SecondDesktop\A_Technology\golang\coze-loop\frontend\apps\cozeloop
node ..\..\..\common\scripts\install-run-rushx.js dev
```
`install-run-rushx.js` 会调用项目锁定版本的 RushX 启动 dev server。

## 4. 关于 API 代理映射（什么时候加的、加在哪里）

- 文件：`frontend/apps/cozeloop/rsbuild.config.ts`
- 位置：`server` 配置
- 修改内容：已添加
  ```ts
  server: { port, proxy: { '/api': 'http://localhost:8888' } },
  ```
  作用：开发模式下（`rushx dev`），将前端发往 `/api` 的请求代理到本地后端 `http://localhost:8888`，无需容器内 nginx。

## 5. 常见问题

- `rushx` 不是内部或外部命令：使用上面的 `install-run-rushx.js`，或安装 Rush 到用户目录（避免 Program Files 权限）。
- 端口被占用：前端默认 8090；如冲突，修改 `frontend/apps/cozeloop/rsbuild.config.ts` 中的 `port`，并重启 dev server。
- 后端未启动或健康检查未通过：确保先按 `BACKEND_LOCAL_START.md` 启动后端，并确认依赖服务健康。
- **Windows 路径过长导致 Build failed / IO error 123**：pnpm 的 `.pnpm` 路径过长会触发。
  解决方法（任选其一）：
  1) 在当前终端只设置短路径的 PNPM store，并重装依赖（不要设置 RUSH_TEMP_FOLDER，否则 workspace 安装不兼容）：
  ```powershell
  $env:RUSH_PNPM_STORE_PATH="D:\pnpm-store" # 缩短 pnpm store 路径
  cd D:\AAA_SecondDesktop\A_Technology\golang\coze-loop
  rush purge --unsafe
   rush install --purge --to @cozeloop/community-base --ignore-hooks
  ```
  然后重新 `node ..\..\..\common\scripts\install-run-rushx.js dev`。
  2) 或者将仓库移动/映射到更短的盘符路径（例如 `D:\coze-loop`，或用 `subst X: D:\AAA_SecondDesktop\A_Technology\golang\coze-loop`，然后在 `X:` 下执行安装与启动）。

## 6. 验证

- 前端启动后访问 `http://localhost:8090`（或你修改后的端口）。
- 浏览器开发者工具 Network 中 `/api/**` 请求应指向 `http://localhost:8888` 并有响应。
