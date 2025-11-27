---
description: Guia para parar o ambiente de desenvolvimento Chatwoot no Windows (WSL)
---

# Stop Chatwoot Development Environment

Você está parando o ambiente de desenvolvimento do Chatwoot.

## 🛑 Como Parar os Processos

### Passo 1: Parar Rails Server (Terminal 1)
```
Pressione: Ctrl+C
```

Aguarde até ver:
```
Exiting
```

---

### Passo 2: Parar Sidekiq (Terminal 2)
```
Pressione: Ctrl+C
```

Aguarde até ver:
```
Bye!
```

**⚠️ IMPORTANTE:** Aguarde o Sidekiq finalizar gracefully (terminar jobs em andamento). Isso pode levar alguns segundos.

---

### Passo 3: Parar Vite (Terminal 3)
```
Pressione: Ctrl+C
```

Aguarde até o processo terminar.

---

## 🔧 Parar Serviços (Opcional)

### Parar Redis

Se quiser economizar recursos:

```bash
sudo service redis-server stop
```

Verificar se parou:
```bash
redis-cli ping
```
**Esperado:** Erro de conexão (significa que parou)

---

## 🔍 Verificar se Tudo Foi Parado

### Verificar processos Rails/Sidekiq/Vite
```bash
ps aux | grep -E "(rails|sidekiq|vite)" | grep -v grep
```

**Esperado:** Sem resultados (tudo parado)

### Verificar portas
```bash
# Verificar se porta 3000 está livre
lsof -i :3000

# Verificar se porta 5173 está livre
lsof -i :5173
```

**Esperado:** Sem resultados

---

## ⚠️ Forçar Parada (Emergência)

Se algum processo não parar normalmente:

### Matar Rails
```bash
pkill -9 -f "rails server"
```

### Matar Sidekiq
```bash
pkill -9 -f sidekiq
```

### Matar Vite
```bash
pkill -9 -f vite
```

### Matar tudo de uma vez
```bash
pkill -9 -f "rails server|sidekiq|vite"
```

**⚠️ CUIDADO:** Isso mata os processos abruptamente. Use apenas se `Ctrl+C` não funcionar.

---

## 🧹 Limpeza (Opcional)

Se quiser fazer uma limpeza mais profunda:

### Limpar cache Rails
```bash
rm -rf tmp/cache
```

### Limpar cache Vite
```bash
rm -rf node_modules/.vite public/packs
```

### Limpar logs
```bash
# Ver tamanho dos logs
du -sh log/*.log

# Limpar logs antigos
rm log/*.log
```

---

## 🔄 Reiniciar Ambiente

Se precisar reiniciar (não apenas parar):

1. Pare tudo conforme acima
2. Use `/start-chatwoot` para iniciar novamente

---

## 💾 Salvar Trabalho Antes de Parar

**Lembre-se:**

- [ ] Commit suas mudanças no Git
- [ ] Salvar todos os arquivos abertos no editor
- [ ] Anotar onde parou (para retomar depois)

```bash
# Ver mudanças não commitadas
git status

# Commit rápido
git add .
git commit -m "WIP: descrição do que estava fazendo"
```

---

## 📊 Verificar Estado Antes de Sair

### Ver últimos logs para detectar erros
```bash
tail -50 log/development.log
```

### Ver se há jobs pendentes no Sidekiq
```bash
bundle exec rails console
> Sidekiq::Queue.all.map {|q| [q.name, q.size] }
```

---

## ✅ Checklist de Parada Completa

- [ ] Terminal 1 (Rails): Parado
- [ ] Terminal 2 (Sidekiq): Parado
- [ ] Terminal 3 (Vite): Parado
- [ ] Redis: Parado (opcional)
- [ ] Nenhum processo restante: `ps aux | grep rails` sem resultado
- [ ] Portas livres: `lsof -i :3000` e `lsof -i :5173` sem resultado
- [ ] Git: Mudanças commitadas ou stashed

---

**Ambiente parado com sucesso! 🛑**

Para iniciar novamente, use: `/start-chatwoot`
