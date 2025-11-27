#!/bin/bash

# Configurar PATH com rbenv e nvm
export HOME=/home/afmic
export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
export PATH="$HOME/.nvm/versions/node/v20.19.5/bin:$PATH"

# Habilitar corepack para pnpm
export PATH="/usr/lib/node_modules/corepack/shims:$PATH"
export COREPACK_ENABLE_STRICT=0

# Navegar para o projeto
cd /mnt/d/ivox/chatwoot || exit 1

# Mostrar header
echo "=== VITE DEV SERVER (TERMINAL 3) ==="
echo "Node: $(node -v 2>&1)"
echo "pnpm: $(pnpm -v 2>&1)"
echo ""
echo "Aguarde o Vite iniciar..."
echo ""

# Corrigir line endings se necessário
sed -i 's/\r$//' bin/vite 2>/dev/null
sed -i 's/\r$//' bin/rails 2>/dev/null

# Iniciar Vite
bin/vite dev

# Manter terminal aberto se falhar
exec bash
