#!/bin/bash

echo "🚀 Deploying Activity-Based Presence Feature..."
echo ""

# Navegar para o diretório do Chatwoot
cd /mnt/d/ivox/chatwoot

echo "📦 Step 1: Building Docker images..."
docker compose build

echo ""
echo "🔄 Step 2: Stopping containers..."
docker compose down

echo ""
echo "▶️  Step 3: Starting containers..."
docker compose up -d

echo ""
echo "⏳ Waiting for containers to be ready..."
sleep 10

echo ""
echo "🗄️  Step 4: Running database migration..."
docker compose exec web bundle exec rails db:migrate

echo ""
echo "🎨 Step 5: Precompiling assets..."
docker compose exec web bundle exec rails assets:precompile

echo ""
echo "🔄 Step 6: Restarting web and sidekiq..."
docker compose restart web
docker compose restart sidekiq

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Next steps:"
echo "1. Access your Chatwoot at http://localhost:3000"
echo "2. Go to Settings > Account Settings"
echo "3. Look for 'Activity-Based Presence' section"
echo "4. Enable it and configure timeouts"
echo ""
