-- Busca as credenciais WABA / WhatsApp de uma account.
-- Credenciais ficam em channel_whatsapp.provider_config (jsonb).
-- Inboxes referenciam o canal via channel_type + channel_id.
--
-- Uso: substituir :account_id pelo ID da account alvo.
--   psql -v account_id=123 -f sql/waba_credentials_by_account.sql
--
-- provider = 'whatsapp_cloud' -> Meta Cloud API (WABA oficial)
--   chaves esperadas: api_key, business_account_id, phone_number_id, webhook_verify_token
-- provider = 'default'        -> 360dialog (api_key, eventual url)
--
-- ATENCAO: api_key e token de acesso. Tratar resultado como segredo.

SELECT
  i.id                AS inbox_id,
  i.name              AS inbox_name,
  cw.id               AS channel_id,
  cw.account_id,
  cw.phone_number,
  cw.provider,
  cw.provider_config ->> 'api_key'              AS api_key,
  cw.provider_config ->> 'business_account_id'  AS waba_id,
  cw.provider_config ->> 'phone_number_id'      AS phone_number_id,
  cw.provider_config ->> 'webhook_verify_token' AS webhook_verify_token,
  cw.provider_config ->> 'source'               AS source,
  cw.provider_config                            AS provider_config_full,
  cw.message_templates_last_updated,
  cw.created_at,
  cw.updated_at
FROM channel_whatsapp cw
LEFT JOIN inboxes i
  ON i.channel_id = cw.id
 AND i.channel_type = 'Channel::Whatsapp'
WHERE cw.account_id = :account_id
ORDER BY cw.id;
