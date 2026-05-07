# Deploy Chatwoot Custom (Omniflex)

Guia único para build da imagem Docker custom + deploy de stack no Portainer.

Aplicável a **clientes novos** (banco zerado, v4.13.0) e **sandbox/upgrade** (banco existente, v4.11.1).

Para detalhes específicos de migração de DB de versões antigas, ver:

- `docs/md/migration_352_to_4111_fix.md` (v3.5.2 → v4.11.1)
- `docs/md/deploy_sandbox_4111.md` (checklist sandbox v4.11.1)

---

## Arquivos de stack disponíveis

| Stack                                | Versão Chatwoot | Quando usar                                                              |
| ------------------------------------ | --------------- | ------------------------------------------------------------------------ |
| `chatwoot-cliente-4130.yml` + `.env` | **v4.13.0**     | Cliente novo, banco zerado, MinIO storage                                |
| `chat_appio.yaml` + `.env`           | **v4.11.1**     | **Appio oficial de produção** — AWS S3 + AWS SES (substitui v3.5.2)      |
| `chatwoot-sandbox-4111.yml` + `.env` | v4.11.1         | Sandbox de migração (v3.5.2 → v4.11.1), AWS S3 + SendGrid (legado)       |

---

## 1. Build da imagem Docker

O `Dockerfile` na raiz do repo é um **overlay** que parte da imagem oficial do Chatwoot e copia somente os arquivos custom (`app/`, `config/`, `db/migrate/`, `theme/`, `public/`).

### Pré-requisitos

- Docker Desktop rodando
- Login no Docker Hub: `docker login` (conta `afmichelutti`)
- Branch correta com as customizações em `git checkout`

### Comandos

**v4.13.0 (cliente novo):**

```bash
git checkout experiment/v4.13.0-merge   # ou a branch atual de produção
docker build --no-cache -t afmichelutti/appio_cw_4130:appio .
docker push afmichelutti/appio_cw_4130:appio
```

Trocar `:cliente` pelo identificador do cliente (ex: `:appio`, `:acme`).

**v4.11.1 (sandbox/upgrade):**

```bash
git checkout v4.7.0-custom
docker build --no-cache -t afmichelutti/appio_cw_4111:appio .
docker push afmichelutti/appio_cw_4111:appio
```

### Linha `FROM` no Dockerfile

Sempre conferir se aponta pra versão certa do Chatwoot upstream:

```dockerfile
FROM chatwoot/chatwoot:v4.13.0   # ou v4.11.1
```

Mismatch entre o `FROM` e os arquivos copiados causa erros como:

```
[vite]: Rollup failed to resolve import "virtua/vue"
```

(quando o código copiado é v4.13.0 mas a base é v4.11.1).

---

## 2. Deploy da stack no Portainer

### Pré-requisitos antes do deploy

| Item                | Detalhes                                                                                                                       |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **DNS**             | Registro `A` para `chat<cliente>.appio.com.br` apontando pro IP da VPS. Cloudflare proxy **off** inicialmente (Let's Encrypt). |
| **Database**        | Vazio para cliente novo: `docker exec postgres psql -U <user> -c "CREATE DATABASE chat_<cliente>;"`                            |
| **MinIO bucket**    | (apenas v4.13.0) Console MinIO > Buckets > Create: `chatwoot-<cliente>` + Service Account com read/write nesse bucket          |
| **Imagem**          | Já buildada e pushada no Docker Hub                                                                                            |
| **SECRET_KEY_BASE** | Gerar com `openssl rand -hex 64`                                                                                               |

### Editar o yaml antes do deploy

No `docs/stack/chatwoot-cliente-4130.yml` (ou copia dele), substituir os placeholders:

| String no yaml                     | Substituir por                             |
| ---------------------------------- | ------------------------------------------ |
| `chatwoot_cli` (nome de service)   | `chatwoot_<cliente>` (ex: `chatwoot_acme`) |
| `cliente` (na image tag)           | identificador real (ex: `acme`)            |
| `chatcliente.appio.com.br`         | DNS real (ex: `chatacme.appio.com.br`)     |
| `chat_cliente` (POSTGRES_DATABASE) | nome real (ex: `chat_acme`)                |

### Cadastrar variáveis de ambiente no Portainer

Pegar do arquivo `chatwoot-cliente-4130.env` (ou `.env`). 6 variáveis obrigatórias para v4.13.0:

```
CLI_SECRET_KEY_BASE=<openssl rand -hex 64>
CLI_POSTGRES_PASSWORD=<senha do postgres da VPS>
CLI_STORAGE_ACCESS_KEY_ID=<MinIO service account>
CLI_STORAGE_SECRET_ACCESS_KEY=<MinIO service account>
CLI_STORAGE_BUCKET_NAME=chatwoot-<cliente>
CLI_STORAGE_ENDPOINT=https://minio.appio.com.br
CLI_SMTP_PASSWORD=<SendGrid API key ou similar>
```

⚠️ No Portainer, **não usar aspas** nos valores das env vars (diferente de `.env` local).

### Deploy

Portainer > Stacks > Add stack > Cole o yaml > Cadastre as env vars > Deploy.

---

## 3. Setup do banco (primeira execução)

### Cliente novo (banco zerado)

Após a stack subir, executar UMA vez:

```bash
docker exec <container_web> bundle exec rails db:create db:migrate
```

Isso roda **todas** as migrations, incluindo a custom `20260225120000_add_auto_assign_on_reply_to_inboxes.rb`. Sem isso, todas as inboxes somem do UI (bug documentado em `migration_352_to_4111_fix.md`).

> ⚠️ **NUNCA use `db:chatwoot_prepare` em deploy novo sem validar depois.**
> Ele carrega `db/schema.rb` direto e marca todas as migrations como aplicadas em `schema_migrations`, **mesmo as não refletidas no schema.rb**. Resultado: instalação nasce com `schema_migrations` "completo" mas faltando colunas custom — e `db:migrate:status` reporta tudo `up`, não detecta o problema. Só estoura em runtime quando uma view tenta acessar a coluna inexistente (500 em `/api/v1/accounts/:id`, sidebar de Settings capada).
>
> **Sempre rode `db:create && db:migrate`** ou, se usar `db:chatwoot_prepare`, **valide as colunas custom logo depois** com o script da seção "Detecção" em [`docs/md/fix_schema_migrations_dessincronizado.md`](../md/fix_schema_migrations_dessincronizado.md).

### Cliente migrando de v3.5.2 → v4.11.1

Seguir o playbook completo em `docs/md/migration_352_to_4111_fix.md` — tem 3 fixes obrigatórios via SQL antes do `db:migrate`.

### Cliente migrando v4.11.1 → v4.13.0

Ainda não documentado. As 14 migrations novas do upstream (webhook secrets, Captain backfills, calls, assignment_v2) precisam ser testadas antes. Ver `git log v4.11.1..v4.13.0 -- db/migrate/`.

---

## 4. Criar super admin

```bash
docker exec -it <container_web> bundle exec rails c
```

```ruby
SuperAdmin.create!(email: 'admin@cliente.com', password: 'SENHA_FORTE', confirmed_at: Time.now)
```

Acessar `/super_admin` no domínio para gerenciar.

---

## 5. Testes pós-deploy

```bash
# 1. Containers rodando?
docker ps | grep chatwoot_<cliente>

# 2. Logs sem erro?
docker logs <container_web> --tail 50
docker logs <container_sidekiq> --tail 50

# 3. MinIO acessível do container Chatwoot?
docker exec <container_web> curl -sI https://minio.appio.com.br/minio/health/live
# Esperado: HTTP/2 200

# 4. Banco respondendo?
docker exec <container_web> bundle exec rails runner "puts Account.count"

# 5. Frontend HTTPS?
curl -sI https://chat<cliente>.appio.com.br
# Esperado: HTTP/2 200, certificado Let's Encrypt válido
```

### Testes manuais no UI

- [ ] Login com super admin
- [ ] Criar conta inicial
- [ ] Criar inbox (qualquer canal — confirma que listagem de inboxes funciona, validando que `auto_assign_on_reply` foi criada)
- [ ] Anexar arquivo numa conversa (confirma que MinIO está funcionando)
- [ ] Verificar que email de convite chega (confirma SMTP)

---

## Troubleshooting comum

| Sintoma                                                     | Causa provável                                          | Onde olhar                                |
| ----------------------------------------------------------- | ------------------------------------------------------- | ----------------------------------------- |
| Inboxes somem do UI / 500 em `/api/v1/accounts/:id/inboxes` | Migration custom `20260225120000` não rodou             | `migration_352_to_4111_fix.md` Fix 3      |
| Settings capado (só "Conta" + "Fluxo de Conversa") / 500 em `/api/v1/accounts/:id` com `NoMethodError: undefined method 'activity_based_presence_enabled'` | `db:chatwoot_prepare` rodou com `schema.rb` desatualizado — `schema_migrations` está "completo" mas colunas custom não existem fisicamente | [`fix_schema_migrations_dessincronizado.md`](../md/fix_schema_migrations_dessincronizado.md) |
| `Rollup failed to resolve import "virtua/vue"` no build     | Dockerfile `FROM` não bate com versão do código copiado | Conferir linha 1 do Dockerfile            |
| Anexos não salvam / erro 403 no MinIO                       | Service account sem permissão no bucket                 | Console MinIO > Identity > revisar policy |
| WebSocket "Connection Closed"                               | Traefik sem header `X-Forwarded-Proto=https`            | Ver labels do service no yaml             |
| Bot assume assinatura de atendente humana                   | Conhecido na integração Evolution API                   | `docs/md/auto_offline.md` + memória S121  |
| `Net::SMTPAuthenticationError 535` no Sidekiq               | SMTP do SES com username/password trocados pela access key do S3 | Regenerar credenciais em SES → SMTP Settings |
| Email não chega / SES devolve `MessageRejected`             | Domínio não verificado no SES, ou conta ainda em sandbox SES   | SES → Verified identities + Request production access |

---

## Stack oficial Appio (v4.11.1 + SES) — fluxo dedicado

Este stack (`chat_appio.yaml` + `chat_appio.env`) é a **substituição oficial** da instância v3.5.2 atual rodando na VPS Hostinger KMV8 com 6 clientes. Diferencia-se do sandbox por:

- Database `chat_appio` (não `chat_sand`)
- Domínio `chat.appio.com.br` (ajustar se for outro)
- Prefixo de env vars `APP_*` (não `SAND_*`)
- E-mail via **AWS SES** com `SMTP_AUTHENTICATION=login` (SendGrid foi descartado)

### Pré-requisitos AWS SES

1. **Verificar domínio remetente** em SES Console → Verified identities → adicionar `appio.com.br` com DKIM, SPF e DMARC.
2. **Sair do sandbox SES**: SES → Account Dashboard → *Request production access*. Sem isso, só envia para endereços verificados.
3. **Gerar credenciais SMTP**: SES → SMTP Settings → *Create SMTP Credentials*. Cria um IAM user dedicado com `ses:SendRawEmail`. **Não é a mesma access key do S3** — guardar username/password no Bitwarden.
4. **Endpoint SMTP da região**: usar a mesma região onde o domínio está verificado.
   - `sa-east-1` → `email-smtp.sa-east-1.amazonaws.com`
   - `us-east-1` → `email-smtp.us-east-1.amazonaws.com`

### Deploy do zero — banco novo (sem migração)

> A v3.5.2 atual continua rodando intocada. Esta nova instância sobe ao lado, com **database vazio** e sem cópia de dados — clientes serão recadastrados manualmente quando estiver tudo validado.

1. **Confirmar DNS** apontando `chat.appio.com.br` (ou domínio escolhido) para o IP da VPS, com Cloudflare proxy **off** no primeiro deploy (Let's Encrypt precisa de challenge HTTP).
2. **Criar database vazio**:
   ```bash
   docker exec postgres psql -U <user> -c "CREATE DATABASE chat_appio;"
   ```
3. **Gerar `SECRET_KEY_BASE` novo** (não reaproveitar o da 3.5.2 — instâncias independentes):
   ```bash
   openssl rand -hex 64
   ```
4. **Pré-requisitos AWS SES** já cumpridos (domínio verificado + saída do sandbox + credenciais SMTP geradas).
5. **Deploy stack** `chat_appio.yaml` no Portainer com todas as env vars `APP_*` preenchidas.
6. **Aguardar Rails subir** (logs `docker logs <chatwoot_appio_web> --tail 50`) — o entrypoint roda `db:chatwoot_prepare` automaticamente, criando todas as tabelas a partir de `db/schema.rb` + migrations.
7. **Verificar TODAS as colunas custom** existem fisicamente no banco (não basta olhar `schema_migrations` — ver [`fix_schema_migrations_dessincronizado.md`](../md/fix_schema_migrations_dessincronizado.md) pra entender por que):
   ```bash
   docker exec <chatwoot_appio_web> bundle exec rails runner "
   required = {
     'accounts.activity_based_presence_enabled' => -> { Account.column_names.include?('activity_based_presence_enabled') },
     'accounts.activity_based_presence_config'  => -> { Account.column_names.include?('activity_based_presence_config') },
     'inboxes.auto_assign_on_reply'             => -> { Inbox.column_names.include?('auto_assign_on_reply') }
   }
   required.each { |k, check| puts \"#{check.call ? 'OK   ' : 'FALTA'} #{k}\" }
   "
   ```
   Se aparecer qualquer `FALTA`, **NÃO rode `db:migrate`** (não vai resolver — `schema_migrations` já marca como aplicada). Aplique o SQL de `fix_schema_migrations_dessincronizado.md` (seção "Fix definitivo nessa instalação").
8. **Criar super admin**:
   ```bash
   docker exec -it <chatwoot_appio_web> bundle exec rails c
   ```
   ```ruby
   SuperAdmin.create!(email: 'admin@appio.com.br', password: 'SENHA_FORTE', confirmed_at: Time.now)
   ```
9. **Acessar** `https://chat.appio.com.br/super_admin` → criar primeira conta → criar inbox de teste.
10. **Testar SES**: convidar um agente externo por e-mail → confirmar entrega + checar `From` e domínio.

### Variáveis obrigatórias no Portainer

```
APP_SECRET_KEY_BASE=<MESMO_DA_3.5.2_OU_NOVO>
APP_POSTGRES_USERNAME=<user>
APP_POSTGRES_PASSWORD=<senha>
APP_AWS_ACCESS_KEY_ID=<S3>
APP_AWS_SECRET_ACCESS_KEY=<S3>
APP_S3_BUCKET_NAME=<bucket>
APP_MAILER_SENDER_EMAIL=no-reply@appio.com.br
APP_SES_SMTP_USERNAME=<gerado em SES SMTP Settings>
APP_SES_SMTP_PASSWORD=<gerado em SES SMTP Settings>
APP_SMTP_DOMAIN=appio.com.br
```
