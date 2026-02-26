# Export Conversations to CSV
# Usage: bundle exec rails runner export_conversations_to_csv.rb [ACCOUNT_ID] [START_DATE] [END_DATE] [OUTPUT_FILE]
# Example: bundle exec rails runner export_conversations_to_csv.rb 1 2025-01-01 2025-12-31 output.csv

require 'csv'

# Parameters
ACCOUNT_ID = ARGV[0]&.to_i || 1
START_DATE = ARGV[1] || '2025-01-01'
END_DATE = ARGV[2] || '2025-12-31'
OUTPUT_FILE = ARGV[3] || "conversations_account_#{ACCOUNT_ID}_#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv"

puts "==== Exporting Conversations to CSV ===="
puts "Account ID: #{ACCOUNT_ID}"
puts "Start Date: #{START_DATE}"
puts "End Date: #{END_DATE}"
puts "Output File: #{OUTPUT_FILE}"
puts ""

# SQL Query
sql = <<-SQL
SELECT
    -- Contact Information
    ct.id AS contact_id,
    ct.name AS contact_name,
    ct.email AS contact_email,
    ct.phone_number AS contact_phone,
    ct.identifier AS contact_identifier,
    ct.created_at AS contact_created_at,

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
        WHEN 0 THEN ct.name
        WHEN 1 THEN u_sender.name
        ELSE NULL
    END AS message_sender_name,

    u_sender.email AS sender_email,
    m.sender_id AS sender_id,

    -- Message Metadata
    m.private AS message_is_private,
    m.source_id AS message_source_id,
    m.content_type AS message_content_type,

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
            AND m2.message_type = 0
    ) AS incoming_messages_count,

    (
        SELECT COUNT(*)
        FROM messages m2
        WHERE m2.conversation_id = c.id
            AND m2.message_type = 1
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

    -- CSAT Score
    csat.rating AS csat_rating,
    csat.feedback_message AS csat_feedback

FROM conversations c

INNER JOIN contacts ct ON c.contact_id = ct.id
INNER JOIN inboxes ib ON c.inbox_id = ib.id
LEFT JOIN messages m ON m.conversation_id = c.id
LEFT JOIN users u_assignee ON c.assignee_id = u_assignee.id
LEFT JOIN users u_sender ON m.sender_id = u_sender.id AND m.sender_type = 'User'
LEFT JOIN teams t ON c.team_id = t.id
LEFT JOIN csat_survey_responses csat ON csat.conversation_id = c.id

WHERE c.account_id = $1
    AND c.created_at >= $2::timestamp
    AND c.created_at <= $3::timestamp

ORDER BY c.created_at DESC, m.created_at ASC
SQL

puts "Executing query..."

# Execute query
result = ActiveRecord::Base.connection.exec_query(
  sql,
  'SQL',
  [
    [nil, ACCOUNT_ID],
    [nil, START_DATE],
    [nil, END_DATE]
  ]
)

puts "Found #{result.rows.count} records"

if result.rows.empty?
  puts "No data found for the specified criteria."
  exit 0
end

# Write to CSV
puts "Writing to #{OUTPUT_FILE}..."

CSV.open(OUTPUT_FILE, 'w', encoding: 'UTF-8') do |csv|
  # Header
  csv << result.columns

  # Rows
  result.rows.each_with_index do |row, index|
    csv << row

    # Progress indicator
    if (index + 1) % 1000 == 0
      puts "  Exported #{index + 1} rows..."
    end
  end
end

puts ""
puts "==== Export Complete ===="
puts "Total records: #{result.rows.count}"
puts "Output file: #{OUTPUT_FILE}"
puts "File size: #{File.size(OUTPUT_FILE) / 1024.0 / 1024.0} MB"
puts ""
puts "You can now open #{OUTPUT_FILE} in Excel or any CSV viewer."
