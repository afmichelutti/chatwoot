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

# Iniciar Rails Console
bundle exec rails console
