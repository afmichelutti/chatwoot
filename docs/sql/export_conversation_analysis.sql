-- =====================================================
-- Export Conversation Analysis for Client
-- =====================================================
-- Description: Comprehensive query to export conversation and message data for analysis
-- Output: CSV with contact info, conversation details, messages, and timestamps
-- Usage: Replace ACCOUNT_ID with the target account
-- =====================================================

-- CONFIGURATION
-- Change these values according to your needs:
\set ACCOUNT_ID 1
\set START_DATE '2025-01-01'
\set END_DATE '2025-12-31'

-- =====================================================
-- MAIN QUERY
-- =====================================================

SELECT
    -- Contact Information
    ct.id AS contact_id,
    ct.name AS contact_name,
    ct.email AS contact_email,
    ct.phone_number AS contact_phone,
    ct.identifier AS contact_identifier,
    ct.created_at AS contact_created_at,

    -- Contact Custom Attributes (if any)
    ct.custom_attributes AS contact_custom_attributes,
    ct.additional_attributes AS contact_additional_attributes,

    -- Conversation Information
    c.id AS conversation_id,
    c.display_id AS conversation_display_id,
    c.uuid AS conversation_uuid,

    -- Conversation Status & Priority
    CASE c.status
        WHEN 0 THEN 'open'
        WHEN 1 THEN 'resolved'
        WHEN 2 THEN 'pending'
        WHEN 3 THEN 'snoozed'
        ELSE 'unknown'
    END AS conversation_status,

    CASE c.priority
        WHEN 0 THEN 'low'
        WHEN 1 THEN 'medium'
        WHEN 2 THEN 'high'
        WHEN 3 THEN 'urgent'
        ELSE 'none'
    END AS conversation_priority,

    -- Conversation Dates
    c.created_at AS conversation_created_at,
    c.updated_at AS conversation_updated_at,
    c.last_activity_at AS conversation_last_activity_at,
    c.first_reply_created_at AS conversation_first_reply_at,
    c.snoozed_until AS conversation_snoozed_until,
    c.waiting_since AS conversation_waiting_since,

    -- Conversation Assignment
    u_assignee.name AS assignee_name,
    u_assignee.email AS assignee_email,
    c.assignee_id AS assignee_id,

    -- Team
    t.name AS team_name,
    t.id AS team_id,

    -- Inbox Information
    ib.name AS inbox_name,
    ib.channel_type AS inbox_channel_type,
    ib.id AS inbox_id,

    -- Message Information
    m.id AS message_id,
    m.content AS message_content,
    m.created_at AS message_created_at,
    m.updated_at AS message_updated_at,

    -- Message Type & Status
    CASE m.message_type
        WHEN 0 THEN 'incoming'
        WHEN 1 THEN 'outgoing'
        WHEN 2 THEN 'activity'
        WHEN 3 THEN 'template'
        ELSE 'unknown'
    END AS message_type,

    CASE m.status
        WHEN 0 THEN 'sent'
        WHEN 1 THEN 'delivered'
        WHEN 2 THEN 'read'
        WHEN 3 THEN 'failed'
        ELSE 'unknown'
    END AS message_status,

    -- Message Sender
    CASE m.message_type
        WHEN 0 THEN ct.name  -- Incoming = Contact
        WHEN 1 THEN u_sender.name  -- Outgoing = Agent
        ELSE NULL
    END AS message_sender_name,

    u_sender.email AS sender_email,
    m.sender_id AS sender_id,

    -- Message Metadata
    m.private AS message_is_private,
    m.source_id AS message_source_id,
    m.content_type AS message_content_type,
    m.content_attributes AS message_content_attributes,
    m.additional_attributes AS message_additional_attributes,

    -- Attachments (count)
    (
        SELECT COUNT(*)
        FROM attachments att
        WHERE att.message_id = m.id
    ) AS attachments_count,

    -- Conversation Metrics
    (
        SELECT COUNT(*)
        FROM messages m2
        WHERE m2.conversation_id = c.id
            AND m2.message_type = 0  -- incoming
    ) AS incoming_messages_count,

    (
        SELECT COUNT(*)
        FROM messages m2
        WHERE m2.conversation_id = c.id
            AND m2.message_type = 1  -- outgoing
    ) AS outgoing_messages_count,

    -- Response Time (first reply)
    CASE
        WHEN c.first_reply_created_at IS NOT NULL
        THEN EXTRACT(EPOCH FROM (c.first_reply_created_at - c.created_at))
        ELSE NULL
    END AS first_response_time_seconds,

    -- Conversation Duration
    EXTRACT(EPOCH FROM (c.updated_at - c.created_at)) AS conversation_duration_seconds,

    -- Labels
    c.cached_label_list AS conversation_labels,

    -- Custom Attributes
    c.custom_attributes AS conversation_custom_attributes,
    c.additional_attributes AS conversation_additional_attributes,

    -- CSAT Score (if exists)
    csat.rating AS csat_rating,
    csat.feedback_message AS csat_feedback

FROM conversations c

-- Join Contact
INNER JOIN contacts ct ON c.contact_id = ct.id

-- Join Inbox
INNER JOIN inboxes ib ON c.inbox_id = ib.id

-- Join Messages
LEFT JOIN messages m ON m.conversation_id = c.id

-- Join Assignee (Agent)
LEFT JOIN users u_assignee ON c.assignee_id = u_assignee.id

-- Join Message Sender (Agent)
LEFT JOIN users u_sender ON m.sender_id = u_sender.id AND m.sender_type = 'User'

-- Join Team
LEFT JOIN teams t ON c.team_id = t.id

-- Join CSAT Survey
LEFT JOIN csat_survey_responses csat ON csat.conversation_id = c.id

-- Filters
WHERE c.account_id = :ACCOUNT_ID
    AND c.created_at >= :START_DATE::timestamp
    AND c.created_at <= :END_DATE::timestamp

-- Order by conversation and message creation
ORDER BY
    c.created_at DESC,
    m.created_at ASC;


-- =====================================================
-- ALTERNATIVE: Conversation Summary (without messages)
-- =====================================================
-- Use this for a simpler overview without individual messages

/*
SELECT
    ct.name AS contact_name,
    ct.email AS contact_email,
    ct.phone_number AS contact_phone,

    c.display_id AS conversation_id,

    CASE c.status
        WHEN 0 THEN 'open'
        WHEN 1 THEN 'resolved'
        WHEN 2 THEN 'pending'
        WHEN 3 THEN 'snoozed'
    END AS status,

    c.created_at AS created_at,
    c.last_activity_at AS last_activity_at,

    u_assignee.name AS assigned_to,
    t.name AS team,
    ib.name AS inbox,

    (SELECT COUNT(*) FROM messages WHERE conversation_id = c.id AND message_type = 0) AS incoming_msgs,
    (SELECT COUNT(*) FROM messages WHERE conversation_id = c.id AND message_type = 1) AS outgoing_msgs,

    EXTRACT(EPOCH FROM (c.first_reply_created_at - c.created_at)) AS first_response_seconds,

    csat.rating AS csat_rating

FROM conversations c
INNER JOIN contacts ct ON c.contact_id = ct.id
INNER JOIN inboxes ib ON c.inbox_id = ib.id
LEFT JOIN users u_assignee ON c.assignee_id = u_assignee.id
LEFT JOIN teams t ON c.team_id = t.id
LEFT JOIN csat_survey_responses csat ON csat.conversation_id = c.id

WHERE c.account_id = 1
    AND c.created_at >= '2025-01-01'
    AND c.created_at <= '2025-12-31'

ORDER BY c.created_at DESC;
*/


-- =====================================================
-- HOW TO EXECUTE AND EXPORT TO CSV
-- =====================================================

-- Method 1: Via psql (Command Line)
-- -------------------------------------
-- psql -h pg.slave.omniflex.com.br -p 25060 -U postgres -d chatwoot_new \
--   -v ACCOUNT_ID=1 \
--   -v START_DATE='2025-01-01' \
--   -v END_DATE='2025-12-31' \
--   -f export_conversation_analysis.sql \
--   -o output.csv \
--   --csv


-- Method 2: Via psql with COPY
-- -------------------------------------
-- \copy (SELECT ... FROM ... WHERE ...) TO '/tmp/conversations.csv' WITH CSV HEADER


-- Method 3: Via Rails Console
-- -------------------------------------
-- sql = File.read('docs/sql/export_conversation_analysis.sql')
-- sql.gsub!(':ACCOUNT_ID', '1')
-- sql.gsub!(':START_DATE', "'2025-01-01'")
-- sql.gsub!(':END_DATE', "'2025-12-31'")
-- results = ActiveRecord::Base.connection.execute(sql)
-- CSV.open('output.csv', 'w') do |csv|
--   csv << results.fields
--   results.each { |row| csv << row.values }
-- end


-- Method 4: Using DBeaver or pgAdmin
-- -------------------------------------
-- 1. Connect to database
-- 2. Open new SQL Editor
-- 3. Paste query
-- 4. Replace :ACCOUNT_ID, :START_DATE, :END_DATE with actual values
-- 5. Execute query
-- 6. Right-click results > Export Data > CSV


-- =====================================================
-- FILTERS & CUSTOMIZATION
-- =====================================================

-- Filter by specific inbox:
-- AND c.inbox_id = 86

-- Filter by conversation status:
-- AND c.status IN (0, 1)  -- 0=open, 1=resolved

-- Filter by assignee:
-- AND c.assignee_id = 58

-- Filter by team:
-- AND c.team_id = 5

-- Filter by priority:
-- AND c.priority IN (2, 3)  -- 2=high, 3=urgent

-- Filter only conversations with messages:
-- AND EXISTS (SELECT 1 FROM messages m WHERE m.conversation_id = c.id)

-- Filter by contact phone (WhatsApp):
-- AND ct.phone_number LIKE '+5511%'

-- Filter by message content:
-- AND m.content ILIKE '%keyword%'


-- =====================================================
-- PERFORMANCE TIPS
-- =====================================================

-- 1. Add LIMIT for testing:
-- LIMIT 100

-- 2. Use date indexes (already exist in Chatwoot schema)

-- 3. For large exports, consider batching by date:
-- WHERE c.created_at >= '2025-01-01' AND c.created_at < '2025-02-01'

-- 4. If too slow, remove message-level joins and use summary query

-- 5. Create index if needed (check with DBA first):
-- CREATE INDEX idx_conversations_account_created ON conversations(account_id, created_at);
