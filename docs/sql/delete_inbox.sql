-- delete_inbox.sql
-- Deleta uma inbox e todas as suas dependências
-- ATENÇÃO: Esta operação é IRREVERSÍVEL!
--
-- Uso:
--   1. Substitua INBOX_ID_AQUI pelo ID da inbox
--   2. Execute no PostgreSQL
--
-- Exemplo:
--   psql -h HOST -p PORT -U USER -d DATABASE -f delete_inbox.sql

-- ============================================================================
-- CONFIGURAÇÃO
-- ============================================================================

-- ⚠️ SUBSTITUA ESTE VALOR PELO ID DA INBOX QUE DESEJA DELETAR
\set inbox_id 'INBOX_ID_AQUI'

-- ============================================================================
-- DIAGNÓSTICO (execute primeiro para ver o que será deletado)
-- ============================================================================

SELECT 'DIAGNÓSTICO - INBOX ' || :inbox_id AS info;

-- Informações da inbox
SELECT
    i.id,
    i.name,
    i.channel_type,
    i.account_id,
    a.name AS account_name
FROM inboxes i
JOIN accounts a ON i.account_id = a.id
WHERE i.id = :inbox_id;

-- Contagem de dependências
SELECT 'Conversas' AS tipo, COUNT(*) AS total
FROM conversations WHERE inbox_id = :inbox_id
UNION ALL
SELECT 'Mensagens' AS tipo, COUNT(*) AS total
FROM messages m
JOIN conversations c ON m.conversation_id = c.id
WHERE c.inbox_id = :inbox_id
UNION ALL
SELECT 'ContactInboxes' AS tipo, COUNT(*) AS total
FROM contact_inboxes WHERE inbox_id = :inbox_id
UNION ALL
SELECT 'InboxMembers' AS tipo, COUNT(*) AS total
FROM inbox_members WHERE inbox_id = :inbox_id
UNION ALL
SELECT 'TeamInboxes' AS tipo, COUNT(*) AS total
FROM team_inboxes WHERE inbox_id = :inbox_id;

-- ============================================================================
-- DELEÇÃO (descomente para executar)
-- ============================================================================

-- ⚠️ ATENÇÃO: REMOVA OS COMENTÁRIOS (--) ABAIXO PARA EXECUTAR A DELEÇÃO
-- ⚠️ ESTA OPERAÇÃO É IRREVERSÍVEL!

-- BEGIN;

-- -- 1. Deletar mensagens (via conversas)
-- DELETE FROM messages
-- WHERE conversation_id IN (
--     SELECT id FROM conversations WHERE inbox_id = :inbox_id
-- );

-- -- 2. Deletar eventos das conversas
-- DELETE FROM events
-- WHERE conversation_id IN (
--     SELECT id FROM conversations WHERE inbox_id = :inbox_id
-- );

-- -- 3. Deletar conversation_participants
-- DELETE FROM conversation_participants
-- WHERE conversation_id IN (
--     SELECT id FROM conversations WHERE inbox_id = :inbox_id
-- );

-- -- 4. Deletar notifications relacionadas
-- DELETE FROM notifications
-- WHERE primary_actor_type = 'Conversation'
--   AND primary_actor_id IN (
--       SELECT id FROM conversations WHERE inbox_id = :inbox_id
--   );

-- -- 5. Deletar conversas
-- DELETE FROM conversations WHERE inbox_id = :inbox_id;

-- -- 6. Deletar contact_inboxes
-- DELETE FROM contact_inboxes WHERE inbox_id = :inbox_id;

-- -- 7. Deletar inbox_members
-- DELETE FROM inbox_members WHERE inbox_id = :inbox_id;

-- -- 8. Deletar team_inboxes
-- DELETE FROM team_inboxes WHERE inbox_id = :inbox_id;

-- -- 9. Deletar webhooks
-- DELETE FROM webhooks WHERE inbox_id = :inbox_id;

-- -- 10. Deletar working_hours
-- DELETE FROM working_hours WHERE inbox_id = :inbox_id;

-- -- 11. Deletar channel (dependendo do tipo)
-- -- Para Channel::Api:
-- DELETE FROM channel_api WHERE id IN (
--     SELECT channel_id FROM inboxes WHERE id = :inbox_id AND channel_type = 'Channel::Api'
-- );

-- -- Para Channel::WebWidget:
-- DELETE FROM channel_web_widgets WHERE id IN (
--     SELECT channel_id FROM inboxes WHERE id = :inbox_id AND channel_type = 'Channel::WebWidget'
-- );

-- -- Para Channel::Whatsapp:
-- DELETE FROM channel_whatsapp WHERE id IN (
--     SELECT channel_id FROM inboxes WHERE id = :inbox_id AND channel_type = 'Channel::Whatsapp'
-- );

-- -- Para Channel::Email:
-- DELETE FROM channel_email WHERE id IN (
--     SELECT channel_id FROM inboxes WHERE id = :inbox_id AND channel_type = 'Channel::Email'
-- );

-- -- Para Channel::Telegram:
-- DELETE FROM channel_telegram WHERE id IN (
--     SELECT channel_id FROM inboxes WHERE id = :inbox_id AND channel_type = 'Channel::Telegram'
-- );

-- -- Para Channel::Line:
-- DELETE FROM channel_line WHERE id IN (
--     SELECT channel_id FROM inboxes WHERE id = :inbox_id AND channel_type = 'Channel::Line'
-- );

-- -- Para Channel::Sms (Twilio):
-- DELETE FROM channel_twilio_sms WHERE id IN (
--     SELECT channel_id FROM inboxes WHERE id = :inbox_id AND channel_type = 'Channel::TwilioSms'
-- );

-- -- 12. Finalmente, deletar a inbox
-- DELETE FROM inboxes WHERE id = :inbox_id;

-- COMMIT;

-- ============================================================================
-- VERIFICAÇÃO PÓS-DELEÇÃO
-- ============================================================================

-- Descomente após a deleção para verificar
-- SELECT 'Inbox deletada com sucesso!' AS resultado
-- WHERE NOT EXISTS (SELECT 1 FROM inboxes WHERE id = :inbox_id);
