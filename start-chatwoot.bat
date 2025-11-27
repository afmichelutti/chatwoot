@echo off
REM ============================================
REM Chatwoot Development Environment Starter
REM ============================================
REM
REM Este script abre 3 terminais WSL para rodar:
REM 1. Rails Server (porta 3000)
REM 2. Sidekiq (background jobs)
REM 3. Vite (frontend dev server)
REM
REM ============================================

echo.
echo ========================================
echo   Chatwoot Development Environment
echo ========================================
echo.
echo Iniciando ambiente de desenvolvimento...
echo.

REM Verificar se WSL está instalado
wsl --list >nul 2>&1
if errorlevel 1 (
    echo [ERRO] WSL nao encontrado!
    echo Por favor, instale o WSL2 primeiro.
    pause
    exit /b 1
)

echo [OK] WSL encontrado
echo.

REM Verificar se distribuição Ubuntu existe
wsl -d Ubuntu -- echo "test" >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Distribuicao Ubuntu nao encontrada!
    echo Execute: wsl --install -d Ubuntu
    pause
    exit /b 1
)

echo [OK] Ubuntu encontrado
echo.

REM Testar se o diretório do projeto existe
wsl -d Ubuntu -- test -d /mnt/d/ivox/chatwoot
if errorlevel 1 (
    echo [ERRO] Diretorio do projeto nao encontrado!
    echo Esperado: /mnt/d/ivox/chatwoot
    echo Verifique o caminho do projeto.
    pause
    exit /b 1
)

echo [OK] Diretorio do projeto encontrado
echo.

REM Iniciar Redis
echo Iniciando Redis...
wsl -d Ubuntu -- sudo service redis-server start

REM Aguardar 2 segundos
timeout /t 2 /nobreak >nul

REM Testar Redis
wsl -d Ubuntu -- redis-cli ping >nul 2>&1
if errorlevel 1 (
    echo [AVISO] Redis nao respondeu. Continue manualmente.
) else (
    echo [OK] Redis iniciado com sucesso
)

echo.
echo ========================================
echo Abrindo terminais...
echo ========================================
echo.
echo Terminal 1: Rails Server (porta 3000)
echo Terminal 2: Sidekiq (background jobs)
echo Terminal 3: Vite (frontend dev server)
echo.
echo Aguarde os 3 terminais abrirem...
echo.

REM Terminal 1: Rails Server
start "Chatwoot - Rails Server" wsl -d Ubuntu -- bash /mnt/d/ivox/chatwoot/scripts/start-rails.sh

REM Aguardar 3 segundos antes de abrir o próximo
timeout /t 3 /nobreak >nul

REM Terminal 2: Sidekiq
start "Chatwoot - Sidekiq" wsl -d Ubuntu -- bash /mnt/d/ivox/chatwoot/scripts/start-sidekiq.sh

REM Aguardar 3 segundos antes de abrir o próximo
timeout /t 3 /nobreak >nul

REM Terminal 3: Vite
start "Chatwoot - Vite Dev Server" wsl -d Ubuntu -- bash /mnt/d/ivox/chatwoot/scripts/start-vite.sh

echo.
echo ========================================
echo   Ambiente Iniciado!
echo ========================================
echo.
echo 3 terminais foram abertos:
echo   1. Rails Server (http://localhost:3000)
echo   2. Sidekiq
echo   3. Vite (http://localhost:5173)
echo.
echo Aguarde ~30-60 segundos para tudo inicializar.
echo.
echo Quando estiver pronto, acesse:
echo   http://localhost:3000
echo.
echo Para parar: Pressione Ctrl+C em cada terminal
echo ou execute: stop-chatwoot.bat
echo.
echo ========================================
echo.

REM Aguardar 10 segundos antes de abrir o navegador
timeout /t 10 /nobreak >nul

REM Perguntar se quer abrir o navegador
set /p OPEN_BROWSER="Abrir navegador agora? (S/N): "
if /i "%OPEN_BROWSER%"=="S" (
    echo Abrindo navegador...
    start http://localhost:3000
)

echo.
echo Pressione qualquer tecla para fechar esta janela...
pause >nul
