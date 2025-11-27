@echo off
REM ============================================
REM Chatwoot Development Environment Checker
REM ============================================
REM
REM Este script verifica o status do ambiente:
REM - WSL e distribuicao Ubuntu
REM - Versoes (Ruby, Node, pnpm)
REM - Servicos (Redis, PostgreSQL)
REM - Processos rodando (Rails, Sidekiq, Vite)
REM - Portas em uso
REM
REM ============================================

echo.
echo ========================================
echo   Chatwoot Environment Status
echo ========================================
echo.

REM Verificar WSL
echo [1/9] Verificando WSL...
wsl --list >nul 2>&1
if errorlevel 1 (
    echo [ERRO] WSL nao instalado
    goto :end
) else (
    echo [OK] WSL instalado
)

REM Verificar Ubuntu
echo.
echo [2/9] Verificando Ubuntu...
wsl -d Ubuntu -- echo "test" >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Ubuntu nao encontrado
    goto :end
) else (
    echo [OK] Ubuntu encontrado
)

REM Verificar diretório do projeto
echo.
echo [3/9] Verificando diretorio do projeto...
wsl -d Ubuntu -- test -d /mnt/d/ivox/chatwoot
if errorlevel 1 (
    echo [ERRO] Diretorio /mnt/d/ivox/chatwoot nao encontrado
) else (
    echo [OK] Diretorio do projeto existe
)

REM Verificar versões
echo.
echo [4/9] Verificando versoes...
echo.
echo Ruby:
wsl -d Ubuntu -- bash -c "cd /mnt/d/ivox/chatwoot && ruby -v"
echo.
echo Node:
wsl -d Ubuntu -- bash -c "cd /mnt/d/ivox/chatwoot && node -v"
echo.
echo pnpm:
wsl -d Ubuntu -- bash -c "cd /mnt/d/ivox/chatwoot && pnpm -v"

REM Verificar Redis
echo.
echo [5/9] Verificando Redis...
wsl -d Ubuntu -- redis-cli ping >nul 2>&1
if errorlevel 1 (
    echo [AVISO] Redis nao esta rodando
    echo Execute: wsl -d Ubuntu -- sudo service redis-server start
) else (
    echo [OK] Redis esta rodando (responde PONG)
)

REM Verificar conexão com banco de dados
echo.
echo [6/9] Verificando conexao com banco de dados...
wsl -d Ubuntu -- bash -c "cd /mnt/d/ivox/chatwoot && bundle exec rails db:version 2>&1 | head -5"

REM Verificar processos rodando
echo.
echo [7/9] Verificando processos rodando...
echo.

wsl -d Ubuntu -- bash -c "ps aux | grep 'rails server' | grep -v grep" >nul 2>&1
if errorlevel 1 (
    echo [X] Rails Server: NAO RODANDO
) else (
    echo [OK] Rails Server: RODANDO
)

wsl -d Ubuntu -- bash -c "ps aux | grep 'sidekiq' | grep -v grep" >nul 2>&1
if errorlevel 1 (
    echo [X] Sidekiq: NAO RODANDO
) else (
    echo [OK] Sidekiq: RODANDO
)

wsl -d Ubuntu -- bash -c "ps aux | grep 'vite' | grep -v grep" >nul 2>&1
if errorlevel 1 (
    echo [X] Vite: NAO RODANDO
) else (
    echo [OK] Vite: RODANDO
)

REM Verificar portas
echo.
echo [8/9] Verificando portas em uso...
echo.

netstat -ano | findstr ":3000" >nul 2>&1
if errorlevel 1 (
    echo [X] Porta 3000 (Rails): LIVRE
) else (
    echo [OK] Porta 3000 (Rails): EM USO
)

netstat -ano | findstr ":5173" >nul 2>&1
if errorlevel 1 (
    echo [X] Porta 5173 (Vite): LIVRE
) else (
    echo [OK] Porta 5173 (Vite): EM USO
)

netstat -ano | findstr ":6379" >nul 2>&1
if errorlevel 1 (
    echo [X] Porta 6379 (Redis): LIVRE
) else (
    echo [OK] Porta 6379 (Redis): EM USO
)

REM Status geral
echo.
echo [9/9] Status Geral...
echo.

set ALL_RUNNING=1

wsl -d Ubuntu -- bash -c "ps aux | grep 'rails server' | grep -v grep" >nul 2>&1
if errorlevel 1 set ALL_RUNNING=0

wsl -d Ubuntu -- bash -c "ps aux | grep 'sidekiq' | grep -v grep" >nul 2>&1
if errorlevel 1 set ALL_RUNNING=0

wsl -d Ubuntu -- bash -c "ps aux | grep 'vite' | grep -v grep" >nul 2>&1
if errorlevel 1 set ALL_RUNNING=0

wsl -d Ubuntu -- redis-cli ping >nul 2>&1
if errorlevel 1 set ALL_RUNNING=0

echo ========================================
echo.

if %ALL_RUNNING%==1 (
    echo [OK] AMBIENTE COMPLETO RODANDO!
    echo.
    echo Tudo esta funcionando:
    echo   - Rails Server: http://localhost:3000
    echo   - Vite: http://localhost:5173
    echo   - Sidekiq: Rodando
    echo   - Redis: Rodando
    echo.
    echo Voce esta pronto para desenvolver!
) else (
    echo [AVISO] AMBIENTE INCOMPLETO
    echo.
    echo Alguns componentes nao estao rodando.
    echo.
    echo Para iniciar o ambiente completo:
    echo   start-chatwoot.bat
    echo.
    echo Ou inicie manualmente:
    echo   /start-chatwoot
)

echo.
echo ========================================
echo.

:end
echo Pressione qualquer tecla para fechar...
pause >nul
