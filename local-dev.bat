@echo off
setlocal

echo === Coze Loop local dev starter ===
echo Assumes WSL docker-compose deps are running (redis/mysql/clickhouse/minio/rocketmq/faas)
echo.

rem --- Prefer 64-bit Go in Program Files if present ---
if exist "C:\Program Files\Go\bin\go.exe" (
  set "PATH=C:\Program Files\Go\bin;%PATH%"
)

rem --- Go version check (require >= 1.24) ---
set "GOVERSION="
for /f "tokens=1" %%v in ('go env GOVERSION 2^>nul') do set "GOVERSION=%%v"
if "%GOVERSION%"=="" (
  echo [ERROR] Go not found in PATH. Please install Go 1.24.x 64-bit and retry.
  pause
  goto :end
)
echo Detected %GOVERSION%
echo %GOVERSION% | findstr /r "go1\.2[4-9] go1\.[3-9][0-9] go[2-9]\." >nul
if errorlevel 1 (
  echo [ERROR] Go version too low. Require >= 1.24.x (64-bit). Current: %GOVERSION%
  pause
  goto :end
)
for /f "tokens=1" %%a in ('go env GOARCH 2^>nul') do set "GOARCH=%%a"
if "%GOARCH%"=="386" (
  echo [ERROR] Detected 32-bit Go (GOARCH=386). Please use 64-bit Go (GOARCH=amd64).
  pause
  goto :end
)

set "ROOT=%~dp0"
set "DEV_CONF=%ROOT%release\deployment\docker-compose"
set "FRONTEND_DIR=%ROOT%frontend\apps\cozeloop"

start "coze-loop-backend" cmd /k "cd /d %DEV_CONF% ^&^& set PWD=%DEV_CONF% ^&^& set COZE_LOOP_REDIS_DOMAIN=127.0.0.1 ^&^& set COZE_LOOP_REDIS_PORT=6379 ^&^& set COZE_LOOP_REDIS_PASSWORD=cozeloop-redis ^&^& set COZE_LOOP_MYSQL_DOMAIN=127.0.0.1 ^&^& set COZE_LOOP_MYSQL_PORT=3306 ^&^& set COZE_LOOP_MYSQL_USER=root ^&^& set COZE_LOOP_MYSQL_PASSWORD=cozeloop-mysql ^&^& set COZE_LOOP_MYSQL_DATABASE=cozeloop-mysql ^&^& set COZE_LOOP_CLICKHOUSE_DOMAIN=127.0.0.1 ^&^& set COZE_LOOP_CLICKHOUSE_PORT=9000 ^&^& set COZE_LOOP_CLICKHOUSE_USER=default ^&^& set COZE_LOOP_CLICKHOUSE_PASSWORD=cozeloop-clickhouse ^&^& set COZE_LOOP_CLICKHOUSE_DATABASE=cozeloop-clickhouse ^&^& set COZE_LOOP_OSS_PROTOCOL=http ^&^& set COZE_LOOP_OSS_DOMAIN=127.0.0.1 ^&^& set COZE_LOOP_OSS_PORT=9001 ^&^& set COZE_LOOP_OSS_REGION=us-east-1 ^&^& set COZE_LOOP_OSS_USER=root ^&^& set COZE_LOOP_OSS_PASSWORD=cozeloop-minio ^&^& set COZE_LOOP_OSS_BUCKET=cozeloop-minio ^&^& set COZE_LOOP_RMQ_NAMESRV_DOMAIN=127.0.0.1 ^&^& set COZE_LOOP_RMQ_NAMESRV_PORT=9876 ^&^& set COZE_LOOP_PYTHON_FAAS_DOMAIN=127.0.0.1 ^&^& set COZE_LOOP_PYTHON_FAAS_PORT=8000 ^&^& set COZE_LOOP_JS_FAAS_DOMAIN=127.0.0.1 ^&^& set COZE_LOOP_JS_FAAS_PORT=8001 ^&^& go run ..\..\..\backend\cmd"
start "coze-loop-frontend" cmd /k "cd /d %FRONTEND_DIR% ^&^& rushx dev"

echo Backend and frontend consoles launched in new windows.
echo If you don't see them, check taskbar for windows named "coze-loop-backend" and "coze-loop-frontend".
pause
endlocal
:end

