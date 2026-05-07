# Bug em produção — schema_migrations dessincronizado do schema físico

> **Status:** padrão recorrente. Aplicado workaround em produção (Appio, Doraia). Fix de raiz pendente em `db/schema.rb` — ver seção "O que precisa ser feito no repo".

---

## Contexto

Repo do Chatwoot fork Omniflex/Appio (imagem publicada como `afmichelutti/appio_cw_4130:appio`, baseada no Chatwoot ~v4.13). A instalação self-hosted desse fork apresenta um padrão recorrente de bug em produção que **NÃO** é consequência do código da migration em si — é consequência da combinação entre `db/schema.rb` desatualizado e o comando de bootstrap (`db:chatwoot_prepare`).

---

## Sintoma observado em produção

`GET /api/v1/accounts/:id` retornava **500 Internal Server Error**:

```
ActionView::Template::Error
(undefined method 'activity_based_presence_enabled' for an instance of Account):

  app/views/api/v1/models/_account.json.jbuilder:28
  app/views/api/v1/accounts/show.json.jbuilder:1
  app/controllers/api/v1/accounts_controller.rb:21
```

**Efeito em cascata no frontend Vue:** como `/api/v1/accounts/:id` é o endpoint que carrega `enabled_features` na inicialização do dashboard, com ele em 500 a sidebar de Configurações ficou capada (só "Conta" e "Fluxo de Conversa" apareciam) e qualquer "Atualizar" parecia não persistir (na verdade o reload é que falhava).

Mesmo padrão se repetiu depois com a coluna `auto_assign_on_reply` em `inboxes`.

---

## Root cause

Em produção:

1. `SELECT version FROM schema_migrations` contém **todas** as 125+ versões, incluindo as duas problemáticas (`20250118000000`, `20260225120000`).
2. `bundle exec rails db:migrate:status` reporta **zero** migrations em `down`.
3. **MAS** as colunas que essas migrations adicionariam **não existem fisicamente** em `accounts` / `inboxes`.

**Hipótese:** o setup roda `db:chatwoot_prepare` (que internamente chama `db:schema:load` quando o banco está vazio). O `schema:load` carrega `db/schema.rb` — que está **desatualizado** em relação à pasta `db/migrate/` — e em seguida o Rails marca TODAS as migrations presentes em `db/migrate/` como aplicadas em `schema_migrations`, mesmo as que não estão refletidas no `schema.rb`.

**Resultado:** instalação nova fica com `schema_migrations` "completo" mas faltando colunas. E como `db:migrate:status` mostra tudo `up`, a auditoria padrão Rails não detecta o problema. Só descobre quando alguma view/serializer tenta acessar a coluna em runtime e estoura `NoMethodError`.

---

## Workaround aplicado no banco de produção (cirúrgico, não no repo)

```sql
-- migration 20250118000000
ALTER TABLE accounts
  ADD COLUMN activity_based_presence_enabled boolean NOT NULL DEFAULT false,
  ADD COLUMN activity_based_presence_config  jsonb   NOT NULL
  DEFAULT '{"inactivity_timeout_minutes": 10, "busy_timeout_hours": 3}'::jsonb;

-- migration 20260225120000
ALTER TABLE inboxes
  ADD COLUMN IF NOT EXISTS auto_assign_on_reply boolean NOT NULL DEFAULT true;

-- migration 20250118000001 (data migration — idempotente)
UPDATE account_users SET auto_offline = true WHERE auto_offline = false;
```

Não foi feito INSERT em `schema_migrations` (já estavam lá). Containers `plataformav4_chatwoot_appio` e `_sidekiq` foram restartados com `docker service update --force` pra Rails recarregar `Account.column_names` / `Inbox.column_names`.

---

## Migrations Omniflex/Appio custom problemáticas (lista vivendo neste repo)

| Migration | Adiciona | Tabela | Em `schema.rb`? |
|---|---|---|---|
| `20250118000000_add_activity_based_presence_to_accounts` | `activity_based_presence_enabled` (bool), `activity_based_presence_config` (jsonb) | `accounts` | ❌ NÃO |
| `20250118000001_set_auto_offline_to_true` | (data migration — sem coluna) | — | n/a |
| `20260225120000_add_auto_assign_on_reply_to_inboxes` | `auto_assign_on_reply` (bool) | `inboxes` | ❌ NÃO |

> **Manutenção desta lista:** sempre que adicionar uma migration custom (timestamp ≥ 2025), revalidar se ela está refletida em `db/schema.rb` antes de buildar uma imagem nova.

---

## Detecção em uma instalação existente

Roda no container Rails da VPS suspeita:

```bash
docker exec <CONTAINER_WEB> bundle exec rails runner "
required = {
  'accounts.activity_based_presence_enabled' => -> { Account.column_names.include?('activity_based_presence_enabled') },
  'accounts.activity_based_presence_config'  => -> { Account.column_names.include?('activity_based_presence_config') },
  'inboxes.auto_assign_on_reply'             => -> { Inbox.column_names.include?('auto_assign_on_reply') }
}
required.each { |k, check| puts \"#{check.call ? 'OK  ' : 'FALTA '} #{k}\" }
"
```

Se aparecer qualquer `FALTA`, aplique o workaround SQL acima nessa instalação.

---

## Fix definitivo nessa instalação (script copy-paste pra rodar em qualquer VPS afetada)

```bash
# 1. Descobrir nome do container postgres + database
docker ps --format 'table {{.Names}}\t{{.Image}}' | grep -iE 'postgres|chatwoot|appio'

# 2. Aplicar o ALTER TABLE em transação (substitua os placeholders)
docker exec <CONTAINER_POSTGRES> psql -U <PG_USER> -d <DB_NAME> -c "
BEGIN;

ALTER TABLE accounts
  ADD COLUMN IF NOT EXISTS activity_based_presence_enabled boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS activity_based_presence_config  jsonb   NOT NULL
  DEFAULT '{\"inactivity_timeout_minutes\": 10, \"busy_timeout_hours\": 3}'::jsonb;

ALTER TABLE inboxes
  ADD COLUMN IF NOT EXISTS auto_assign_on_reply boolean NOT NULL DEFAULT true;

UPDATE account_users SET auto_offline = true WHERE auto_offline = false;

-- Garante que schema_migrations tem as 3 versions (idempotente)
INSERT INTO schema_migrations (version) VALUES
  ('20250118000000'),
  ('20250118000001'),
  ('20260225120000')
ON CONFLICT (version) DO NOTHING;

COMMIT;
"

# 3. Restart dos services pra Rails recarregar column_names
docker service update --force <STACK>_chatwoot_appio
docker service update --force <STACK>_chatwoot_appio_sidekiq

# 4. Validar (no container web)
docker exec <CONTAINER_WEB> bundle exec rails runner "
[Account.column_names.include?('activity_based_presence_enabled'),
 Inbox.column_names.include?('auto_assign_on_reply')].all? ? puts('OK') : puts('FALHOU')
"
```

**Rollback** (se precisar reverter):

```sql
BEGIN;
ALTER TABLE accounts
  DROP COLUMN IF EXISTS activity_based_presence_enabled,
  DROP COLUMN IF EXISTS activity_based_presence_config;
ALTER TABLE inboxes DROP COLUMN IF EXISTS auto_assign_on_reply;
DELETE FROM schema_migrations WHERE version IN ('20250118000000','20250118000001','20260225120000');
COMMIT;
```

---

## O que precisa ser feito no repo (fix de raiz, pendente)

### 1. Auditar `db/schema.rb` vs. `db/migrate/`

Comparar as definições de colunas em `db/schema.rb` (tabela `accounts`, `inboxes`, e qualquer outra alterada por migrations 2025/2026) contra o que as migrations em `db/migrate/2025*.rb` e `db/migrate/2026*.rb` deveriam ter aplicado. Listar todas as **divergências** (colunas que migrations adicionam mas não estão em `schema.rb`).

Começar por:

- `db/migrate/20250118000000_add_activity_based_presence_to_accounts.rb` — confirmar se o `add_column` está refletido em `schema.rb` na tabela `accounts`.
- `db/migrate/20260225120000_add_auto_assign_on_reply_to_inboxes.rb` — idem em `inboxes`.
- Varrer todas as migrations 2026 (`ls db/migrate/2026*.rb`). Para cada `add_column`, `create_table`, `add_index`, `change_column`, conferir se está em `schema.rb`.

### 2. Regenerar `db/schema.rb`

Se confirmar divergência (provável):

```bash
# em dev, com banco limpo:
bin/rails db:drop db:create db:migrate
# isso re-dump o schema.rb
git diff db/schema.rb
```

Commitar o `schema.rb` atualizado. **Esse é o fix de raiz** — instalações novas a partir desta versão da imagem não terão mais o problema.

### 3. Validar o fluxo de bootstrap (`db:chatwoot_prepare`)

Ler `lib/tasks/chatwoot.rake` (ou onde a task `db:chatwoot_prepare` estiver definida) e confirmar:

- Se ela usa `db:schema:load` quando banco está vazio, o `schema.rb` precisa estar correto (item 2 acima).
- Considerar substituir por `db:migrate` no fluxo de bootstrap pra evitar dependência do `schema.rb` (mais lento mas à prova de schema.rb desatualizado).
- OU adicionar um `db:migrate` no final do `db:chatwoot_prepare` (idempotente — se schema.rb estiver correto, vira no-op).

### 4. Backfill nos ambientes que já estão rodando a versão bugada

Adicionar uma rake task ou migration de "reconciliação" que detecta e corrige o estado dessincronizado em instalações existentes:

```ruby
# pseudocódigo
unless Account.column_names.include?('activity_based_presence_enabled')
  ActiveRecord::Migration.new.add_column :accounts, :activity_based_presence_enabled, :boolean, default: false, null: false
end
# ... idem para as outras colunas
```

OU documentar em `UPGRADE.md` o conjunto de `ALTER TABLE` que admins devem rodar manualmente (quem já está em produção).

---

## Restrição importante

**Não remover/recriar nenhuma migration existente** — só atualizar o `db/schema.rb` para refletir o estado correto e ajustar o `db:chatwoot_prepare` se necessário. Migrations já têm timestamps fixos e instalações que rodaram corretamente não devem ser re-tocadas.

---

## Output que espero do agent que pegar essa task

1. Lista de todas as colunas/índices/tabelas que estão em migrations 2025-2026 mas faltando em `db/schema.rb`.
2. Diff do `db/schema.rb` regenerado (commit pronto, no branch atual).
3. Análise do `db:chatwoot_prepare` — se o problema está nele, proposta de fix.
4. Migration de reconciliação (ou seção em `UPGRADE.md`) cobrindo as colunas que faltavam.

---

## Histórico de incidentes documentados

| Data | Cliente | Versão | Colunas afetadas | Workaround | Fix de raiz aplicado? |
|---|---|---|---|---|---|
| 2026-04-27 | Doraia | 4.13.0 | `auto_assign_on_reply` | manual | ❌ |
| 2026-05-07 | Appio | 4.13.0 | `activity_based_presence_*`, `auto_assign_on_reply` | SQL+restart services | ❌ |

> **Atualizar essa tabela** sempre que outra instalação for afetada, até o fix de raiz estar mergeado.

---

## Referências internas

- `docs/stack/DEPLOY.md` — guia de deploy (já alerta sobre `db:chatwoot_prepare` vs `db:migrate`, mas o aviso não foi suficiente)
- `docs/md/migration_352_to_4111_fix.md` — bug similar em migração v3.5.2 → v4.11.1 (mesmo padrão de migration custom não aplicada)
- `db/migrate/20250118000000_add_activity_based_presence_to_accounts.rb`
- `db/migrate/20260225120000_add_auto_assign_on_reply_to_inboxes.rb`
- `app/views/api/v1/models/_account.json.jbuilder:28-29` — onde o NoMethodError estoura
