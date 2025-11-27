#!/bin/bash

echo "🚀 Setting up Chatwoot Development Environment..."
echo ""

# Navegar para o diretório
cd /mnt/d/ivox/chatwoot

echo "📦 Step 1: Installing Ruby gems..."
bundle install

echo ""
echo "📦 Step 2: Installing Node packages..."
yarn install

echo ""
echo "🔑 Step 3: Generating SECRET_KEY_BASE..."
SECRET_KEY=$(bundle exec rake secret)
sed -i "s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$SECRET_KEY/" .env

echo ""
echo "🗄️  Step 4: Starting PostgreSQL..."
sudo service postgresql start

echo ""
echo "🗄️  Step 5: Creating database..."
bundle exec rails db:create

echo ""
echo "🗄️  Step 6: Running migrations..."
bundle exec rails db:migrate

echo ""
echo "📊 Step 7: Seeding database (optional - creates demo data)..."
read -p "Do you want to seed the database with demo data? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    bundle exec rails db:seed
fi

echo ""
echo "🔴 Step 8: Starting Redis..."
sudo service redis-server start

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 To start development servers, run these commands in separate terminals:"
echo ""
echo "  Terminal 1 (Rails):   bundle exec rails server -p 3000"
echo "  Terminal 2 (Sidekiq): bundle exec sidekiq"
echo "  Terminal 3 (Webpack): bin/webpack-dev-server"
echo ""
echo "Then access: http://localhost:3000"
echo ""
