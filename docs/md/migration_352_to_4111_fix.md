# Migração Chatwoot 3.5.2 → 4.11.1: Fix de Migrations

## Problema

Ao rodar `bundle exec rails db:chatwoot_prepare`, a migration falha em:

```
20250416182131_flip_chatwoot_v4_default_feature_flag_installation_config.rb
```

**Erro:**
```
NoMethodError: undefined method 'accessor' for an instance of ActiveModel::Type::Value
  captain_featurable.rb:52 in validate_captain_models
```

**Causa raiz:** A migration chama `account.enable_features!('chatwoot_v4')` que faz `save` no
model Account. O `save` dispara a validação `validate_captain_models` do concern
`CaptainFeaturable`, que usa `type_for_attribute(store_attribute).accessor` — método
incompatível com Ruby 3.4 / Rails 7.x nesta versão.

## Migrations Problemáticas

| # | Migration | Problema | Status |
|---|-----------|----------|--------|
| 1 | `20250416182131` FlipChatwootV4DefaultFeatureFlag | `account.enable_features!` → `save` → validação falha | **FIX NECESSÁRIO** |
| 2 | `20250421085134` UpdateAutoResolveToMminutes | `account.save!` → potencial falha | **PASSOU SEM FIX** (captain_models era blank) |

Na prática, apenas o Fix 1 foi necessário. O Fix 2 está documentado como contingência
caso falhe em outro ambiente com dados diferentes.

## Solução: Aplicar via SQL + marcar como migradas

### Passo 1: Fix da Migration 20250416182131 (Feature Flag chatwoot_v4)

`chatwoot_v4` é o feature flag na posição **38** da lista `config/features.yml`.
FlagShihTzu armazena flags como bitmask: posição 38 → bit 2^37 = **137438953472**.

```bash
docker exec -it <CONTAINER_ID> bundle exec rails runner "
  # 1. Atualizar InstallationConfig
  config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
  if config && config.value.present?
    features = config.value.map do |f|
      f['name'] == 'chatwoot_v4' ? f.merge('enabled' => true) : f
    end
    config.update_column(:value, features.to_json)
    puts 'InstallationConfig atualizado'
  end

  # 2. Habilitar chatwoot_v4 em todas as accounts via SQL direto (sem validação)
  bit_value = 2**37  # 137438953472
  count = ActiveRecord::Base.connection.execute(
    \"UPDATE accounts SET feature_flags = feature_flags | #{bit_value}\"
  ).cmd_tuples
  puts \"#{count} accounts atualizadas com chatwoot_v4\"

  # 3. Marcar migration como executada
  ActiveRecord::Base.connection.execute(
    \"INSERT INTO schema_migrations (version) VALUES ('20250416182131') ON CONFLICT DO NOTHING\"
  )
  puts 'Migration 20250416182131 marcada como executada'

  GlobalConfig.clear_cache
  puts 'Cache limpo'
"
```

### Passo 2: Fix da Migration 20250421085134 (Auto Resolve to Minutes)

Esta migration converte `auto_resolve_duration` (em dias) para `auto_resolve_after` (em minutos)
no campo jsonb `settings`. A coluna `settings` é adicionada pela migration anterior
(`20250421082927`) que é DDL pura e roda sem problema.

**IMPORTANTE:** Primeiro rode as migrations normais para que a migration `20250421082927`
(que adiciona a coluna `settings`) rode antes desta:

```bash
docker exec -it <CONTAINER_ID> bundle exec rails db:migrate
```

Se parar na `20250421085134`, aplicar via SQL:

```bash
docker exec -it <CONTAINER_ID> bundle exec rails runner "
  # Converter auto_resolve_duration (dias) para auto_resolve_after (minutos)
  count = ActiveRecord::Base.connection.execute(\"
    UPDATE accounts
    SET settings = jsonb_set(
      COALESCE(settings, '{}'),
      '{auto_resolve_after}',
      to_jsonb((auto_resolve_duration * 60 * 24)::integer)
    )
    WHERE auto_resolve_duration IS NOT NULL
  \").cmd_tuples
  puts \"#{count} accounts atualizadas com auto_resolve_after\"

  # Marcar migration como executada
  ActiveRecord::Base.connection.execute(
    \"INSERT INTO schema_migrations (version) VALUES ('20250421085134') ON CONFLICT DO NOTHING\"
  )
  puts 'Migration 20250421085134 marcada como executada'
"
```

### Passo 3: Rodar as migrations restantes

Depois de aplicar os 2 fixes acima, rodar novamente:

```bash
docker exec -it <CONTAINER_ID> bundle exec rails db:migrate
```

As migrations restantes são DDL puro e devem rodar sem problemas:

| Migration | Descrição | Risco |
|-----------|-----------|-------|
| `20250421082927` | Add settings column to account | Nenhum (add_column) |
| `20250512231036` | Create copilot_threads | Nenhum (create_table) |
| `20250512231037` | Create copilot_messages | Nenhum (create_table) |
| `20250514045638` | Add csat_config to inboxes | Nenhum (add_column) |
| `20250523024825` | Remove uuid from copilot_threads | Nenhum (DDL) |
| `20250523024826` | Remove user_id from copilot_messages | Nenhum (DDL) |
| `20250523031839` | Change message_type in copilot_messages | Nenhum (DDL) |
| `20250620120000` | Create channel_voice | Nenhum (create_table) |
| `20250627195529` | Add index to messages | Nenhum (add_index) |
| `20260225120000` | Add auto_assign_on_reply to inboxes (custom) | Nenhum (add_column) |

### Passo 4: Verificar que todas rodaram

```bash
docker exec -it <CONTAINER_ID> bundle exec rails db:migrate:status | grep down
```

Se retornar vazio = todas as migrations executadas com sucesso.

## Resumo Rápido (Copiar e Colar)

Sequência completa de comandos no container do sandbox:

```bash
# 1. Primeiro: aplicar fix da migration 20250416182131
bundle exec rails runner "
config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
if config && config.value.present?
  features = config.value.map { |f| f['name'] == 'chatwoot_v4' ? f.merge('enabled' => true) : f }
  config.update_column(:value, features.to_json)
end
ActiveRecord::Base.connection.execute('UPDATE accounts SET feature_flags = feature_flags | 137438953472')
ActiveRecord::Base.connection.execute(\"INSERT INTO schema_migrations (version) VALUES ('20250416182131') ON CONFLICT DO NOTHING\")
GlobalConfig.clear_cache
puts 'Fix 1 OK'
"

# 2. Rodar migrations (vai executar 20250421082927 e parar na 20250421085134)
bundle exec rails db:migrate

# 3. Se parar na 20250421085134, aplicar fix
bundle exec rails runner "
ActiveRecord::Base.connection.execute(\"
  UPDATE accounts
  SET settings = jsonb_set(COALESCE(settings, '{}'), '{auto_resolve_after}', to_jsonb((auto_resolve_duration * 60 * 24)::integer))
  WHERE auto_resolve_duration IS NOT NULL
\")
ActiveRecord::Base.connection.execute(\"INSERT INTO schema_migrations (version) VALUES ('20250421085134') ON CONFLICT DO NOTHING\")
puts 'Fix 2 OK'
"

# 4. Rodar migrations restantes
bundle exec rails db:migrate

# 5. Verificar
bundle exec rails db:migrate:status | grep down
```

## Resultado do Sandbox (2026-02-26)

- **~70+ migrations** executadas com sucesso (3.5.2 → 4.11.1)
- **Apenas Fix 1** foi necessário (feature flag chatwoot_v4 via SQL bitmask)
- Fix 2 (auto_resolve) **NÃO foi necessário** — passou automaticamente
- Tempo total de migração: ~10 segundos (após Fix 1)

## Notas para Migração em Produção

- Este mesmo procedimento se aplica ao migrar a produção de 3.5.2 para 4.11.1
- Fazer backup COMPLETO do database antes de iniciar
- **OBRIGATÓRIO:** Aplicar Fix 1 antes de rodar `db:migrate`
- Fix 2 pode ser necessário dependendo dos dados (manter como contingência)
- Testar todo o procedimento no sandbox primeiro
- Bug de compatibilidade Ruby 3.4 no Chatwoot (captain_featurable.rb)
- Reportar upstream: https://github.com/chatwoot/chatwoot/issues
