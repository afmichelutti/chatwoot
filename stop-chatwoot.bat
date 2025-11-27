@echo off
REM ============================================
REM Chatwoot Development Environment Stopper
REM ============================================
REM
REM Este script para todos os processos do Chatwoot:
REM - Rails Server
REM - Sidekiq
REM - Vite
REM - Redis (opcional)
REM
REM ============================================

echo.
echo ========================================
echo   Parar Chatwoot Development Environment
echo ========================================
echo.
echo Parando todos os processos...
echo.

REM Verificar se WSL está rodando
wsl -d Ubuntu -- echo "test" >nul 2>&1
if errorlevel 1 (
    echo [AVISO] Ubuntu WSL nao esta rodando.
    echo Nada para parar.
    pause
    exit /b 0
)

echo [OK] Ubuntu WSL encontrado
echo.

REM Parar Rails
echo Parando Rails Server...
wsl -d Ubuntu -- pkill -f "rails server"
if errorlevel 1 (
    echo [INFO] Rails nao estava rodando
) else (
    echo [OK] Rails parado
)

REM Aguardar 1 segundo
timeout /t 1 /nobreak >nul

REM Parar Sidekiq
echo Parando Sidekiq...
wsl -d Ubuntu -- pkill -f "sidekiq"
if errorlevel 1 (
    echo [INFO] Sidekiq nao estava rodando
) else (
    echo [OK] Sidekiq parado
)

REM Aguardar 1 segundo
timeout /t 1 /nobreak >nul

REM Parar Vite
echo Parando Vite...
wsl -d Ubuntu -- pkill -f "vite"
if errorlevel 1 (
    echo [INFO] Vite nao estava rodando
) else (
    echo [OK] Vite parado
)

echo.
echo ========================================
echo.

REM Perguntar se quer parar Redis também
set /p STOP_REDIS="Parar Redis tambem? (S/N): "
if /i "%STOP_REDIS%"=="S" (
    echo Parando Redis...
    wsl -d Ubuntu -- sudo service redis-server stop
    echo [OK] Redis parado
) else (
    echo [INFO] Redis continua rodando
)

echo.
echo ========================================
echo.

REM Verificar se ainda há processos rodando
echo Verificando processos restantes...
wsl -d Ubuntu -- bash -c "ps aux | grep -E '(rails|sidekiq|vite)' | grep -v grep" >nul 2>&1
if errorlevel 1 (
    echo [OK] Nenhum processo do Chatwoot rodando
) else (
    echo [AVISO] Ainda ha processos rodando:
    wsl -d Ubuntu -- bash -c "ps aux | grep -E '(rails|sidekiq|vite)' | grep -v grep"
    echo.
    set /p FORCE_KILL="Forcar parada? (S/N): "
    if /i "!FORCE_KILL!"=="S" (
        echo Forcando parada de todos os processos...
        wsl -d Ubuntu -- pkill -9 -f "rails server"
        wsl -d Ubuntu -- pkill -9 -f "sidekiq"
        wsl -d Ubuntu -- pkill -9 -f "vite"
        echo [OK] Processos forcados a parar
    )
)

echo.
echo ========================================
echo   Ambiente Parado!
echo ========================================
echo.
echo Todos os processos do Chatwoot foram parados.
echo.
echo Para iniciar novamente:
echo   start-chatwoot.bat
echo.
echo ========================================
echo.
echo Pressione qualquer tecla para fechar...
pause >nul
