#!/bin/bash

echo "🧹 Limpando cache do frontend..."

# Limpar cache do Vite
rm -rf node_modules/.vite
rm -rf .vite

# Limpar cache do Rails
rm -rf tmp/cache

# Limpar public/packs
rm -rf public/packs

# Limpar cache do navegador forçando rebuild
rm -rf app/javascript/.vite

echo "✅ Cache limpo!"
echo ""
echo "🔄 Agora você precisa:"
echo "1. Parar o terminal do Vite (Ctrl+C no Terminal 3)"
echo "2. Rodar novamente: bin/vite dev"
echo "3. No navegador, fazer Hard Refresh (Ctrl+Shift+R)"
echo ""
