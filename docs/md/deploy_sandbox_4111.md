# Deploy Chatwoot Sandbox 4.11.1 - Checklist Completo

## Pré-requisitos

- [ ] Acesso SSH à VPS (`root@srv463687`)
- [ ] Acesso ao Portainer
- [ ] Acesso ao painel DNS (Cloudflare ou registrador)
- [ ] Valores das env vars `CW_*` da stack de produção em mãos

---

## FASE 1: DNS

- [ ] Criar registro DNS para `chatsandbox.appio.com.br`
  - Tipo: `A`
  - Valor: IP da VPS (mesmo IP do `chat.appio.com.br` ou equivalente)
  - TTL: 300 (5 min para propagar rápido)
  - Se Cloudflare: proxy OFF (nuvem cinza) inicialmente, para Traefik gerar o certificado Let's Encrypt

- [ ] Verificar propagação DNS:
```bash
dig chatsandbox.appio.com.br +short
# Deve retornar o IP da VPS
```

---

## FASE 2: Gerar Secret Key

- [ ] Na VPS, gerar o `SECRET_KEY_BASE` do sandbox:
```bash
openssl rand -hex 64
```
- [ ] Anotar o valor gerado (será usado como `SAND_SECRET_KEY_BASE`)

---

## FASE 3: Preparar o Database

### 3.1 Criar o database sandbox
```bash
docker exec postgres psql -U <CW_POSTGRES_USERNAME> -c "CREATE DATABASE chat_sand;"
```

- [ ] Confirmar criação:
```bash
docker exec postgres psql -U <CW_POSTGRES_USERNAME> -c "\l" | grep chat_sand
```

### 3.2 Dump do database de produção
```bash
docker exec postgres pg_dump \
  -U <CW_POSTGRES_USERNAME> \
  -d <CW_POSTGRES_DATABASE> \
  -F c \
  -f /tmp/cw_352_backup.dump
```

- [ ] Verificar tamanho do dump:
```bash
docker exec postgres ls -lh /tmp/cw_352_backup.dump
```

### 3.3 Restaurar no database sandbox
```bash
docker exec postgres pg_restore \
  -U <CW_POSTGRES_USERNAME> \
  -d chat_sand \
  --no-owner \
  --no-privileges \
  /tmp/cw_352_backup.dump
```

> **Nota:** Warnings sobre "role does not exist" podem ser ignorados com segurança.

- [ ] Verificar restauração:
```bash
docker exec postgres psql -U <CW_POSTGRES_USERNAME> -d chat_sand \
  -c "SELECT count(*) FROM accounts;"
```
Deve retornar o mesmo número de accounts da produção.

### 3.4 Limpar dump temporário
```bash
docker exec postgres rm /tmp/cw_352_backup.dump
```

---

## FASE 4: Push da Imagem Docker

- [ ] Garantir que a imagem `afmichelutti/omniflex_cw_4111` está no Docker Hub:
```bash
docker pull afmichelutti/omniflex_cw_4111
```

Se ainda não fez push:
```bash
docker push afmichelutti/omniflex_cw_4111
```

---

## FASE 5: Deploy da Stack no Portainer

### 5.1 Criar a Stack

- [ ] No Portainer → Stacks → Add Stack
- [ ] Nome da stack: `chatwoot_sandbox`
- [ ] Colar o conteúdo do arquivo `chatwoot-sandbox-4111.yml`

### 5.2 Configurar Environment Variables

No Portainer, na seção "Environment variables", adicionar:

```
SAND_INSTALLATION_NAME       = Appio Sandbox
SAND_SECRET_KEY_BASE         = <valor gerado na FASE 2>
SAND_POSTGRES_HOST           = postgres
SAND_POSTGRES_PORT           = 5432
SAND_POSTGRES_USERNAME       = <copiar de CW_POSTGRES_USERNAME>
SAND_POSTGRES_PASSWORD       = <copiar de CW_POSTGRES_PASSWORD>
SAND_AWS_ACCESS_KEY_ID       = <copiar de CW_AWS_ACCESS_KEY_ID>
SAND_AWS_SECRET_ACCESS_KEY   = <copiar de CW_AWS_SECRET_ACCESS_KEY>
SAND_AWS_REGION              = sa-east-1
SAND_S3_BUCKET_NAME          = <copiar de CW_S3_BUCKET_NAME>
SAND_MAILER_SENDER_EMAIL     = <copiar de CW_MAILER_SENDER_EMAIL>
SAND_SMTP_ADDRESS            = smtp.sendgrid.net
SAND_SMTP_PORT               = 587
SAND_SMTP_USERNAME           = <copiar de CW_SMTP_USERNAME>
SAND_SMTP_PASSWORD           = <copiar de CW_SMTP_PASSWORD>
SAND_SMTP_DOMAIN             = <copiar de CW_SMTP_DOMAIN>
```

- [ ] Todas as 16 variáveis preenchidas
- [ ] Clicar **Deploy the stack**

### 5.3 Verificar containers

- [ ] Todos os 3 containers rodando (redis, web, sidekiq):
```bash
docker ps | grep sandbox
```

- [ ] Verificar logs do Rails (esperar inicialização):
```bash
docker service logs chatwoot_sandbox_chatwoot_sandbox --tail 50 -f
```
Aguardar aparecer: `Listening on http://0.0.0.0:3000`

---

## FASE 6: Rodar Migrations (3.5.2 → 4.11.1)

Esta é a etapa mais crítica. São ~60+ migrations entre as versões.

### 6.1 Identificar o container Rails do sandbox
```bash
docker ps | grep "chatwoot_sandbox_chatwoot_sandbox\." | awk '{print $1}'
```

### 6.2 Executar migrations
```bash
docker exec -it <CONTAINER_ID> bundle exec rails db:chatwoot_prepare
```

- [ ] Migrations iniciadas
- [ ] Sem erros fatais nos logs

> **Tempo estimado:** 2-10 minutos dependendo do tamanho do DB.
>
> **Se falhar:** Verificar o erro específico. Erros comuns:
> - `PG::UndefinedTable` → Alguma migration fora de ordem, tentar `rails db:migrate` direto
> - `PG::DuplicateColumn` → Column já existe, geralmente seguro ignorar
> - Timeout → Rodar novamente, migrations são idempotentes

### 6.3 Verificar que migrations rodaram
```bash
docker exec <CONTAINER_ID> bundle exec rails db:migrate:status | tail -20
```
Todas devem estar com status `up`.

---

## FASE 7: Verificação Final

### 7.1 Acesso web
- [ ] Abrir `https://chatsandbox.appio.com.br`
- [ ] Certificado SSL válido (Let's Encrypt via Traefik)
- [ ] Tela de login carregou

### 7.2 Login
- [ ] Login com credenciais de admin (mesmas da produção, pois o DB é cópia)
- [ ] Dashboard carregou sem erros

### 7.3 Funcionalidades básicas
- [ ] Conversas existentes visíveis
- [ ] Inboxes listando corretamente
- [ ] Contatos acessíveis
- [ ] Sidebar e navegação funcionando

### 7.4 Health check
```bash
curl -s https://chatsandbox.appio.com.br/auth/sign_in | head -5
```
Deve retornar HTML (status 200).

### 7.5 Recursos da VPS pós-deploy
```bash
docker stats --no-stream | grep -E "sandbox|postgres|CONTAINER"
```
- [ ] RAM do sandbox dentro do esperado (~1-2 GB total)
- [ ] Postgres não ultrapassou 6 GB

---

## FASE 8: Pós-Deploy (Opcional)

### 8.1 Desabilitar webhooks/integrações do sandbox
Para evitar que o sandbox dispare webhooks para sistemas reais:
```bash
docker exec <CONTAINER_ID> bundle exec rails runner "
  Webhook.update_all(status: 'disabled')
  puts 'Webhooks desabilitados'
"
```

### 8.2 Limpar dados sensíveis (se necessário)
Se outras pessoas vão acessar o sandbox:
```bash
docker exec <CONTAINER_ID> bundle exec rails runner "
  # Anonimizar emails de contatos
  Contact.where.not(email: nil).update_all(email: 'sandbox@test.com')
  puts 'Contatos anonimizados'
"
```

### 8.3 Cloudflare (se aplicável)
- [ ] Após confirmar que SSL funciona, ativar proxy Cloudflare (nuvem laranja)

---

## Troubleshooting

### Container não inicia
```bash
docker service logs chatwoot_sandbox_chatwoot_sandbox --tail 100
```

### Erro de conexão com Postgres
```bash
docker exec <CONTAINER_ID> bundle exec rails runner "puts ActiveRecord::Base.connection.active?"
# Deve retornar: true
```

### Erro de conexão com Redis
```bash
docker exec <CONTAINER_ID> bundle exec rails runner "puts Sidekiq.redis { |r| r.ping }"
# Deve retornar: PONG
```

### Migration travou
```bash
# Ver status das migrations
docker exec <CONTAINER_ID> bundle exec rails db:migrate:status | grep down

# Rodar migration específica se necessário
docker exec <CONTAINER_ID> bundle exec rails db:migrate
```

### Resetar sandbox (recomeçar do zero)
```bash
# Dropar e recriar o database
docker exec postgres psql -U <user> -c "DROP DATABASE chat_sand;"
docker exec postgres psql -U <user> -c "CREATE DATABASE chat_sand;"
# Repetir FASE 3.2 e 3.3, depois FASE 6
```

---

## Resumo de Impacto na VPS

| Recurso | Antes | Depois | Margem |
|---------|-------|--------|--------|
| RAM usada | ~17 GB | ~21 GB | ~11 GB livres |
| Disco usado | 99 GB | ~102 GB | ~278 GB livres |
| Containers | ~40 | ~43 | OK |
