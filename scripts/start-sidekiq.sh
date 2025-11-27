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
echo "=== SIDEKIQ (TERMINAL 2) ==="
echo "Ruby: $(ruby -v 2>&1 | head -1)"
echo "Node: $(node -v 2>&1)"
echo ""
echo "Aguarde o Sidekiq iniciar..."
echo ""

# Iniciar Sidekiq
bundle exec sidekiq

# Manter terminal aberto se falhar
exec bash
