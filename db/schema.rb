# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_10_03_091242) do
  # These extensions should be enabled to support this database
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "access_tokens", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_access_tokens_on_owner_type_and_owner_id"
    t.index ["token"], name: "index_access_tokens_on_token", unique: true
  end

  create_table "account_saml_settings", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "sso_url"
    t.text "certificate"
    t.string "sp_entity_id"
    t.string "idp_entity_id"
    t.json "role_mappings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_saml_settings_on_account_id"
  end

  create_table "account_users", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "user_id"
    t.integer "role", default: 0
    t.bigint "inviter_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "active_at", precision: nil
    t.integer "availability", default: 0, null: false
    t.boolean "auto_offline", default: true, null: false
    t.bigint "custom_role_id"
    t.bigint "agent_capacity_policy_id"
    t.index ["account_id", "user_id"], name: "uniq_user_id_per_account_id", unique: true
    t.index ["account_id"], name: "index_account_users_on_account_id"
    t.index ["agent_capacity_policy_id"], name: "index_account_users_on_agent_capacity_policy_id"
    t.index ["custom_role_id"], name: "index_account_users_on_custom_role_id"
    t.index ["user_id"], name: "index_account_users_on_user_id"
  end

  create_table "accounts", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "locale", default: 16
    t.string "domain", limit: 100
    t.string "support_email", limit: 100
    t.bigint "feature_flags", default: 33029775, null: false
    t.integer "auto_resolve_duration"
    t.jsonb "limits", default: {}
    t.jsonb "custom_attributes", default: {}
    t.integer "status", default: 0
    t.jsonb "internal_attributes", default: {}, null: false
    t.jsonb "settings", default: {}
    t.boolean "auto_assign_team_on_agent_transfer", default: false, null: false
    t.boolean "filter_conversations_by_team", default: false, null: false
    t.boolean "auto_assign_teams_on_transfer", default: false, null: false
    t.boolean "activity_based_presence_enabled", default: false, null: false
    t.jsonb "activity_based_presence_config", default: {"busy_timeout_hours" => 3, "inactivity_timeout_minutes" => 10}, null: false
    t.index ["status"], name: "index_accounts_on_status"
  end

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agent_bot_inboxes", force: :cascade do |t|
    t.integer "inbox_id"
    t.integer "agent_bot_id"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
  end

  create_table "agent_bots", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "outgoing_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id"
    t.integer "bot_type", default: 0
    t.jsonb "bot_config", default: {}
    t.index ["account_id"], name: "index_agent_bots_on_account_id"
  end

  create_table "agent_capacity_policies", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", limit: 255, null: false
    t.text "description"
    t.jsonb "exclusion_rules", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_agent_capacity_policies_on_account_id"
  end

  create_table "applied_slas", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "sla_policy_id", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sla_status", default: 0
    t.index ["account_id", "sla_policy_id", "conversation_id"], name: "index_applied_slas_on_account_sla_policy_conversation", unique: true
    t.index ["account_id"], name: "index_applied_slas_on_account_id"
    t.index ["conversation_id"], name: "index_applied_slas_on_conversation_id"
    t.index ["sla_policy_id"], name: "index_applied_slas_on_sla_policy_id"
  end

  create_table "articles", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "portal_id", null: false
    t.integer "category_id"
    t.integer "folder_id"
    t.string "title"
    t.text "description"
    t.text "content"
    t.integer "status"
    t.integer "views"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "author_id"
    t.bigint "associated_article_id"
    t.jsonb "meta", default: {}
    t.string "slug", null: false
    t.integer "position"
    t.string "locale", default: "en", null: false
    t.index ["account_id"], name: "index_articles_on_account_id"
    t.index ["associated_article_id"], name: "index_articles_on_associated_article_id"
    t.index ["author_id"], name: "index_articles_on_author_id"
    t.index ["portal_id"], name: "index_articles_on_portal_id"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
    t.index ["status"], name: "index_articles_on_status"
    t.index ["views"], name: "index_articles_on_views"
  end

  create_table "assignment_policies", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", limit: 255, null: false
    t.text "description"
    t.integer "assignment_order", default: 0, null: false
    t.integer "conversation_priority", default: 0, null: false
    t.integer "fair_distribution_limit", default: 100, null: false
    t.integer "fair_distribution_window", default: 3600, null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], name: "index_assignment_policies_on_account_id_and_name", unique: true
    t.index ["account_id"], name: "index_assignment_policies_on_account_id"
    t.index ["enabled"], name: "index_assignment_policies_on_enabled"
  end

  create_table "attachments", id: :serial, force: :cascade do |t|
    t.integer "file_type", default: 0
    t.string "external_url"
    t.float "coordinates_lat", default: 0.0
    t.float "coordinates_long", default: 0.0
    t.integer "message_id", null: false
    t.integer "account_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "fallback_title"
    t.string "extension"
    t.jsonb "meta", default: {}
    t.index ["account_id"], name: "index_attachments_on_account_id"
    t.index ["message_id"], name: "index_attachments_on_message_id"
  end

  create_table "audits", force: :cascade do |t|
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.bigint "associated_id"
    t.string "associated_type"
    t.bigint "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.jsonb "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at", precision: nil
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "automation_rules", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "event_name", null: false
    t.jsonb "conditions", default: "{}", null: false
    t.jsonb "actions", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.index ["account_id"], name: "index_automation_rules_on_account_id"
  end

  create_table "cadence_activity_logs", id: :serial, force: :cascade do |t|
    t.integer "cadence_execution_id"
    t.integer "contact_id", null: false
    t.integer "account_id", null: false
    t.string "activity_type", limit: 100, null: false
    t.jsonb "activity_data", default: {}
    t.jsonb "old_values", default: {}
    t.jsonb "new_values", default: {}
    t.integer "user_id"
    t.datetime "created_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "idx_cadence_activity_logs_account_id"
    t.index ["activity_type"], name: "idx_cadence_activity_logs_activity_type"
    t.index ["cadence_execution_id"], name: "idx_cadence_activity_logs_cadence_execution_id"
    t.index ["contact_id"], name: "idx_cadence_activity_logs_contact_id"
    t.index ["created_at"], name: "idx_cadence_activity_logs_created_at"
  end

  create_table "cadence_executions", id: :serial, force: :cascade do |t|
    t.integer "cadence_flow_id", null: false
    t.integer "contact_id", null: false
    t.integer "account_id", null: false
    t.bigint "channel_whatsapp_id", null: false
    t.integer "current_step", default: 0, null: false
    t.string "status", limit: 50, default: "active", null: false
    t.string "qualification_status", limit: 50
    t.integer "qualification_score"
    t.jsonb "qualification_data", default: {}
    t.string "trigger_source", limit: 100
    t.jsonb "trigger_data", default: {}
    t.datetime "last_message_at", precision: 3
    t.datetime "next_message_at", precision: 3
    t.datetime "started_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "completed_at", precision: 3
    t.datetime "cancelled_at", precision: 3
    t.text "cancelled_reason"
    t.jsonb "metadata", default: {}
    t.index ["account_id"], name: "idx_cadence_executions_account_id"
    t.index ["contact_id", "cadence_flow_id", "status"], name: "cadence_executions_contact_flow_active_unique", unique: true, where: "((status)::text = 'active'::text)"
    t.index ["contact_id"], name: "idx_cadence_executions_contact_id"
    t.index ["next_message_at"], name: "idx_cadence_executions_next_message_at"
    t.index ["qualification_status"], name: "idx_cadence_executions_qualification_status"
    t.index ["status"], name: "idx_cadence_executions_status"
  end

  create_table "cadence_flows", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "name", limit: 255, null: false
    t.text "description"
    t.string "status", limit: 50, default: "active", null: false
    t.string "trigger_type", limit: 100, default: "no_response", null: false
    t.jsonb "trigger_conditions", default: {}
    t.datetime "created_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "idx_cadence_flows_account_id"
    t.index ["status"], name: "idx_cadence_flows_status"
  end

  create_table "cadence_interactions", id: :serial, force: :cascade do |t|
    t.integer "cadence_execution_id", null: false
    t.integer "contact_id", null: false
    t.string "interaction_type", limit: 50, null: false
    t.text "message_content"
    t.jsonb "webhook_data", default: {}
    t.string "qualification_impact", limit: 50
    t.jsonb "ai_analysis", default: {}
    t.datetime "created_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["cadence_execution_id"], name: "idx_cadence_interactions_cadence_execution_id"
    t.index ["contact_id"], name: "idx_cadence_interactions_contact_id"
    t.index ["created_at"], name: "idx_cadence_interactions_created_at"
    t.index ["interaction_type"], name: "idx_cadence_interactions_interaction_type"
  end

  create_table "cadence_messages", id: :serial, force: :cascade do |t|
    t.integer "cadence_execution_id", null: false
    t.integer "cadence_step_id", null: false
    t.integer "contact_id", null: false
    t.string "job_id", limit: 255
    t.datetime "scheduled_at", precision: 3, null: false
    t.datetime "sent_at", precision: 3
    t.datetime "delivered_at", precision: 3
    t.datetime "read_at", precision: 3
    t.string "status", limit: 50, default: "scheduled", null: false
    t.string "message_type", limit: 50, default: "text", null: false
    t.text "message_content"
    t.string "template_name", limit: 255
    t.jsonb "template_variables", default: {}
    t.string "waba_message_id", limit: 255
    t.string "error_code", limit: 100
    t.text "error_message"
    t.integer "retry_count", default: 0, null: false
    t.datetime "created_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["cadence_execution_id"], name: "idx_cadence_messages_cadence_execution_id"
    t.index ["contact_id"], name: "idx_cadence_messages_contact_id"
    t.index ["scheduled_at"], name: "idx_cadence_messages_scheduled_at"
    t.index ["status"], name: "idx_cadence_messages_status"
    t.index ["waba_message_id"], name: "idx_cadence_messages_waba_message_id"
  end

  create_table "cadence_qualification_configs", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.jsonb "criteria_weights", default: {}, null: false
    t.jsonb "score_thresholds", default: {}, null: false
    t.text "ai_prompt_template"
    t.string "ai_model", limit: 50, default: "gpt-4", null: false
    t.jsonb "qualification_questions", default: {}, null: false
    t.boolean "auto_qualification", default: true, null: false
    t.datetime "created_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false

    t.unique_constraint ["account_id"], name: "cadence_qualification_configs_account_id_key"
  end

  create_table "cadence_steps", id: :serial, force: :cascade do |t|
    t.integer "cadence_flow_id", null: false
    t.integer "step_order", null: false
    t.string "name", limit: 255, null: false
    t.integer "delay_minutes", default: 0, null: false
    t.string "message_type", limit: 50, default: "text", null: false
    t.text "message_content"
    t.string "template_name", limit: 255
    t.string "template_language", limit: 10, default: "pt_BR", null: false
    t.jsonb "template_variables", default: {}
    t.boolean "has_qualification_process", default: false, null: false
    t.jsonb "qualification_criteria", default: {}
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["cadence_flow_id"], name: "idx_cadence_steps_cadence_flow_id"
    t.index ["is_active"], name: "idx_cadence_steps_is_active"
    t.unique_constraint ["cadence_flow_id", "step_order"], name: "cadence_steps_flow_step_unique"
  end

  create_table "cadence_templates", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "name", limit: 255, null: false
    t.string "category", limit: 100, default: "follow_up", null: false
    t.string "template_type", limit: 50, default: "text", null: false
    t.text "content", null: false
    t.jsonb "variables", default: {}
    t.string "waba_template_name", limit: 255
    t.string "language", limit: 10, default: "pt_BR", null: false
    t.string "status", limit: 50, default: "active", null: false
    t.integer "usage_count", default: 0, null: false
    t.datetime "created_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "whatsapp_config_id"
    t.string "waba_template_id", limit: 255
    t.string "waba_template_status", limit: 20, default: "PENDING"
    t.jsonb "components", default: []
    t.string "template_language", limit: 10, default: "pt_BR"
    t.string "template_category", limit: 50, default: "MARKETING"
    t.boolean "allow_category_change", default: true
    t.json "quality_score"
    t.datetime "last_waba_sync", precision: nil
    t.text "waba_sync_error"
    t.text "rejection_reason"
    t.index ["account_id"], name: "idx_cadence_templates_account_id"
    t.index ["category"], name: "idx_cadence_templates_category"
    t.index ["status"], name: "idx_cadence_templates_status"
    t.index ["template_language"], name: "idx_cadence_templates_language"
    t.index ["waba_template_id"], name: "idx_cadence_templates_waba_id"
    t.index ["waba_template_status"], name: "idx_cadence_templates_waba_status"
    t.index ["whatsapp_config_id", "waba_template_status", "template_language"], name: "idx_cadence_templates_approved", where: "((waba_template_status)::text = 'APPROVED'::text)"
    t.index ["whatsapp_config_id"], name: "idx_cadence_templates_whatsapp_config"
    t.check_constraint "template_category::text = ANY (ARRAY['MARKETING'::character varying::text, 'UTILITY'::character varying::text, 'AUTHENTICATION'::character varying::text])", name: "chk_template_category"
    t.check_constraint "waba_template_status::text = ANY (ARRAY['PENDING'::character varying::text, 'APPROVED'::character varying::text, 'REJECTED'::character varying::text, 'PAUSED'::character varying::text, 'DISABLED'::character varying::text, 'ERROR'::character varying::text])", name: "chk_waba_template_status"
  end

  create_table "campaigns", force: :cascade do |t|
    t.integer "display_id", null: false
    t.string "title", null: false
    t.text "description"
    t.text "message", null: false
    t.integer "sender_id"
    t.boolean "enabled", default: true
    t.bigint "account_id", null: false
    t.bigint "inbox_id", null: false
    t.jsonb "trigger_rules", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "campaign_type", default: 0, null: false
    t.integer "campaign_status", default: 0, null: false
    t.jsonb "audience", default: []
    t.datetime "scheduled_at", precision: nil
    t.boolean "trigger_only_during_business_hours", default: false
    t.jsonb "template_params"
    t.index ["account_id"], name: "index_campaigns_on_account_id"
    t.index ["campaign_status"], name: "index_campaigns_on_campaign_status"
    t.index ["campaign_type"], name: "index_campaigns_on_campaign_type"
    t.index ["inbox_id"], name: "index_campaigns_on_inbox_id"
    t.index ["scheduled_at"], name: "index_campaigns_on_scheduled_at"
  end

  create_table "canned_responses", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "short_code"
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "captain_assistants", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "account_id", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "config", default: {}, null: false
    t.jsonb "response_guidelines", default: []
    t.jsonb "guardrails", default: []
    t.index ["account_id"], name: "index_captain_assistants_on_account_id"
  end

  create_table "captain_custom_tools", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.text "description"
    t.string "http_method", default: "GET", null: false
    t.text "endpoint_url", null: false
    t.text "request_template"
    t.text "response_template"
    t.string "auth_type", default: "none"
    t.jsonb "auth_config", default: {}
    t.jsonb "param_schema", default: []
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "slug"], name: "index_captain_custom_tools_on_account_id_and_slug", unique: true
    t.index ["account_id"], name: "index_captain_custom_tools_on_account_id"
  end

  create_table "captain_documents", force: :cascade do |t|
    t.string "name"
    t.string "external_link", null: false
    t.text "content"
    t.bigint "assistant_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "metadata", default: {}
    t.index ["account_id"], name: "index_captain_documents_on_account_id"
    t.index ["assistant_id", "external_link"], name: "index_captain_documents_on_assistant_id_and_external_link", unique: true
    t.index ["assistant_id"], name: "index_captain_documents_on_assistant_id"
    t.index ["status"], name: "index_captain_documents_on_status"
  end

  create_table "captain_inboxes", force: :cascade do |t|
    t.bigint "captain_assistant_id", null: false
    t.bigint "inbox_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["captain_assistant_id", "inbox_id"], name: "index_captain_inboxes_on_captain_assistant_id_and_inbox_id", unique: true
    t.index ["captain_assistant_id"], name: "index_captain_inboxes_on_captain_assistant_id"
    t.index ["inbox_id"], name: "index_captain_inboxes_on_inbox_id"
  end

  create_table "captain_scenarios", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.text "instruction"
    t.jsonb "tools", default: []
    t.boolean "enabled", default: true, null: false
    t.bigint "assistant_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_captain_scenarios_on_account_id"
    t.index ["assistant_id", "enabled"], name: "index_captain_scenarios_on_assistant_id_and_enabled"
    t.index ["assistant_id"], name: "index_captain_scenarios_on_assistant_id"
    t.index ["enabled"], name: "index_captain_scenarios_on_enabled"
  end

  create_table "categories", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "portal_id", null: false
    t.string "name"
    t.text "description"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale", default: "en"
    t.string "slug", null: false
    t.bigint "parent_category_id"
    t.bigint "associated_category_id"
    t.string "icon", default: ""
    t.index ["associated_category_id"], name: "index_categories_on_associated_category_id"
    t.index ["locale", "account_id"], name: "index_categories_on_locale_and_account_id"
    t.index ["locale"], name: "index_categories_on_locale"
    t.index ["parent_category_id"], name: "index_categories_on_parent_category_id"
    t.index ["slug", "locale", "portal_id"], name: "index_categories_on_slug_and_locale_and_portal_id", unique: true
  end

  create_table "channel_api", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "webhook_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
    t.string "hmac_token"
    t.boolean "hmac_mandatory", default: false
    t.jsonb "additional_attributes", default: {}
    t.index ["hmac_token"], name: "index_channel_api_on_hmac_token", unique: true
    t.index ["identifier"], name: "index_channel_api_on_identifier", unique: true
  end

  create_table "channel_email", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "email", null: false
    t.string "forward_to_email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "imap_enabled", default: false
    t.string "imap_address", default: ""
    t.integer "imap_port", default: 0
    t.string "imap_login", default: ""
    t.string "imap_password", default: ""
    t.boolean "imap_enable_ssl", default: true
    t.boolean "smtp_enabled", default: false
    t.string "smtp_address", default: ""
    t.integer "smtp_port", default: 0
    t.string "smtp_login", default: ""
    t.string "smtp_password", default: ""
    t.string "smtp_domain", default: ""
    t.boolean "smtp_enable_starttls_auto", default: true
    t.string "smtp_authentication", default: "login"
    t.string "smtp_openssl_verify_mode", default: "none"
    t.boolean "smtp_enable_ssl_tls", default: false
    t.jsonb "provider_config", default: {}
    t.string "provider"
    t.boolean "verified_for_sending", default: false, null: false
    t.index ["email"], name: "index_channel_email_on_email", unique: true
    t.index ["forward_to_email"], name: "index_channel_email_on_forward_to_email", unique: true
  end

  create_table "channel_facebook_pages", id: :serial, force: :cascade do |t|
    t.string "page_id", null: false
    t.string "user_access_token", null: false
    t.string "page_access_token", null: false
    t.integer "account_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "instagram_id"
    t.index ["page_id", "account_id"], name: "index_channel_facebook_pages_on_page_id_and_account_id", unique: true
    t.index ["page_id"], name: "index_channel_facebook_pages_on_page_id"
  end

  create_table "channel_instagram", force: :cascade do |t|
    t.string "access_token", null: false
    t.datetime "expires_at", null: false
    t.integer "account_id", null: false
    t.string "instagram_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["instagram_id"], name: "index_channel_instagram_on_instagram_id", unique: true
  end

  create_table "channel_line", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "line_channel_id", null: false
    t.string "line_channel_secret", null: false
    t.string "line_channel_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["line_channel_id"], name: "index_channel_line_on_line_channel_id", unique: true
  end

  create_table "channel_sms", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "phone_number", null: false
    t.string "provider", default: "default"
    t.jsonb "provider_config", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phone_number"], name: "index_channel_sms_on_phone_number", unique: true
  end

  create_table "channel_telegram", force: :cascade do |t|
    t.string "bot_name"
    t.integer "account_id", null: false
    t.string "bot_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bot_token"], name: "index_channel_telegram_on_bot_token", unique: true
  end

  create_table "channel_twilio_sms", force: :cascade do |t|
    t.string "phone_number"
    t.string "auth_token", null: false
    t.string "account_sid", null: false
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "medium", default: 0
    t.string "messaging_service_sid"
    t.string "api_key_sid"
    t.jsonb "content_templates", default: {}
    t.datetime "content_templates_last_updated"
    t.index ["account_sid", "phone_number"], name: "index_channel_twilio_sms_on_account_sid_and_phone_number", unique: true
    t.index ["messaging_service_sid"], name: "index_channel_twilio_sms_on_messaging_service_sid", unique: true
    t.index ["phone_number"], name: "index_channel_twilio_sms_on_phone_number", unique: true
  end

  create_table "channel_twitter_profiles", force: :cascade do |t|
    t.string "profile_id", null: false
    t.string "twitter_access_token", null: false
    t.string "twitter_access_token_secret", null: false
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "tweets_enabled", default: true
    t.index ["account_id", "profile_id"], name: "index_channel_twitter_profiles_on_account_id_and_profile_id", unique: true
  end

  create_table "channel_voice", force: :cascade do |t|
    t.string "phone_number", null: false
    t.string "provider", default: "twilio", null: false
    t.jsonb "provider_config", null: false
    t.integer "account_id", null: false
    t.jsonb "additional_attributes", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_channel_voice_on_account_id"
    t.index ["phone_number"], name: "index_channel_voice_on_phone_number", unique: true
  end

  create_table "channel_web_widgets", id: :serial, force: :cascade do |t|
    t.string "website_url"
    t.integer "account_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "website_token"
    t.string "widget_color", default: "#1f93ff"
    t.string "welcome_title"
    t.string "welcome_tagline"
    t.integer "feature_flags", default: 7, null: false
    t.integer "reply_time", default: 0
    t.string "hmac_token"
    t.boolean "pre_chat_form_enabled", default: false
    t.jsonb "pre_chat_form_options", default: {}
    t.boolean "hmac_mandatory", default: false
    t.boolean "continuity_via_email", default: true, null: false
    t.text "allowed_domains", default: ""
    t.index ["hmac_token"], name: "index_channel_web_widgets_on_hmac_token", unique: true
    t.index ["website_token"], name: "index_channel_web_widgets_on_website_token", unique: true
  end

  create_table "channel_whatsapp", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "phone_number", null: false
    t.string "provider", default: "default"
    t.jsonb "provider_config", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "message_templates", default: {}
    t.datetime "message_templates_last_updated", precision: nil
    t.index ["phone_number"], name: "index_channel_whatsapp_on_phone_number", unique: true
  end

  create_table "cobrowse_session_events", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.string "event_type", limit: 50, null: false
    t.jsonb "event_data", default: {}
    t.string "user_type", limit: 20, null: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["created_at"], name: "idx_cobrowse_events_created"
    t.index ["event_type"], name: "idx_cobrowse_events_type"
    t.index ["session_id"], name: "idx_cobrowse_events_session"
  end

  create_table "cobrowse_sessions", comment: "Armazena sessões de co-browsing para assistência remota", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "conversation_id"
    t.integer "contact_id"
    t.integer "agent_id", null: false
    t.string "session_token", limit: 255, null: false, comment: "Token único e seguro para identificar a sessão"
    t.text "target_url", comment: "URL inicial para a sessão de co-browse"
    t.string "status", limit: 20, default: "pending"
    t.string "provider", limit: 50, default: "togetherjs", comment: "Provedor usado: togetherjs, jitsi, custom"
    t.datetime "started_at", precision: nil
    t.datetime "ended_at", precision: nil
    t.integer "duration_seconds"
    t.string "client_ip", limit: 45
    t.string "agent_ip", limit: 45
    t.jsonb "metadata", default: {}, comment: "Dados adicionais da sessão como configurações, preferências, etc"
    t.datetime "expires_at", precision: nil, null: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["account_id"], name: "idx_cobrowse_sessions_account"
    t.index ["conversation_id"], name: "idx_cobrowse_sessions_conversation"
    t.index ["expires_at"], name: "idx_cobrowse_sessions_expires"
    t.index ["session_token"], name: "idx_cobrowse_sessions_token"
    t.index ["status"], name: "idx_cobrowse_sessions_status"
    t.unique_constraint ["session_token"], name: "cobrowse_sessions_session_token_key"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "domain"
    t.text "description"
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_companies_on_account_id"
    t.index ["domain", "account_id"], name: "index_companies_on_domain_and_account_id"
    t.index ["name", "account_id"], name: "index_companies_on_name_and_account_id"
  end

  create_table "contact_inboxes", force: :cascade do |t|
    t.bigint "contact_id"
    t.bigint "inbox_id"
    t.string "source_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hmac_verified", default: false
    t.string "pubsub_token"
    t.index ["contact_id"], name: "index_contact_inboxes_on_contact_id"
    t.index ["inbox_id", "source_id"], name: "index_contact_inboxes_on_inbox_id_and_source_id", unique: true
    t.index ["inbox_id"], name: "index_contact_inboxes_on_inbox_id"
    t.index ["pubsub_token"], name: "index_contact_inboxes_on_pubsub_token", unique: true
    t.index ["source_id"], name: "index_contact_inboxes_on_source_id"
  end

  create_table "contact_qualifications", id: :serial, force: :cascade do |t|
    t.integer "contact_id", null: false
    t.integer "account_id", null: false
    t.jsonb "qualification_data", default: {}, null: false
    t.integer "financial_score"
    t.integer "interest_score"
    t.integer "social_score"
    t.integer "behavior_score"
    t.integer "total_score", default: 0, null: false
    t.boolean "qualified", default: false, null: false
    t.text "qualification_reason"
    t.datetime "last_interaction_at", precision: 3
    t.datetime "first_analysis_at", precision: 3
    t.datetime "last_analysis_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "idx_contact_qualifications_account_id"
    t.index ["last_analysis_at"], name: "idx_contact_qualifications_last_analysis_at"
    t.index ["qualified"], name: "idx_contact_qualifications_qualified"
    t.index ["total_score"], name: "idx_contact_qualifications_total_score"
    t.unique_constraint ["contact_id"], name: "contact_qualifications_contact_id_key"
  end

  create_table "contacts", id: :serial, force: :cascade do |t|
    t.string "name", default: ""
    t.string "email"
    t.string "phone_number"
    t.integer "account_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "additional_attributes", default: {}
    t.string "identifier"
    t.jsonb "custom_attributes", default: {}
    t.datetime "last_activity_at", precision: nil
    t.string "image", limit: 255
    t.string "fantasy", limit: 100
    t.string "identification", limit: 18
    t.string "state_registration", limit: 50
    t.string "other_registration", limit: 50
    t.string "postalcode", limit: 15
    t.string "streetname", limit: 150
    t.string "streetnumber", limit: 15
    t.text "complement"
    t.string "neighborhood", limit: 100
    t.string "city", limit: 100
    t.string "state", limit: 2
    t.string "website", limit: 150
    t.integer "contact_type", default: 0
    t.string "middle_name", default: ""
    t.string "last_name", default: ""
    t.string "location", default: ""
    t.string "country_code", default: ""
    t.boolean "blocked", default: false, null: false
    t.bigint "company_id"
    t.index "lower((email)::text), account_id", name: "index_contacts_on_lower_email_account_id"
    t.index ["account_id", "contact_type"], name: "index_contacts_on_account_id_and_contact_type"
    t.index ["account_id", "email", "phone_number", "identifier"], name: "index_contacts_on_nonempty_fields", where: "(((email)::text <> ''::text) OR ((phone_number)::text <> ''::text) OR ((identifier)::text <> ''::text))"
    t.index ["account_id", "last_activity_at"], name: "idx_contacts_activity", where: "(last_activity_at IS NOT NULL)"
    t.index ["account_id", "last_activity_at"], name: "index_contacts_on_account_id_and_last_activity_at", order: { last_activity_at: "DESC NULLS LAST" }
    t.index ["account_id"], name: "index_contacts_on_account_id"
    t.index ["account_id"], name: "index_resolved_contact_account_id", where: "(((email)::text <> ''::text) OR ((phone_number)::text <> ''::text) OR ((identifier)::text <> ''::text))"
    t.index ["blocked"], name: "index_contacts_on_blocked"
    t.index ["company_id"], name: "index_contacts_on_company_id"
    t.index ["email", "account_id"], name: "uniq_email_per_account_contact", unique: true
    t.index ["identifier", "account_id"], name: "uniq_identifier_per_account_contact", unique: true
    t.index ["phone_number", "account_id"], name: "index_contacts_on_phone_number_and_account_id"
  end

  create_table "conversation_participants", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_conversation_participants_on_account_id"
    t.index ["conversation_id"], name: "index_conversation_participants_on_conversation_id"
    t.index ["user_id", "conversation_id"], name: "index_conversation_participants_on_user_id_and_conversation_id", unique: true
    t.index ["user_id"], name: "index_conversation_participants_on_user_id"
  end

  create_table "conversations", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "inbox_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "assignee_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "contact_id"
    t.integer "display_id", null: false
    t.datetime "contact_last_seen_at", precision: nil
    t.datetime "agent_last_seen_at", precision: nil
    t.jsonb "additional_attributes", default: {}
    t.bigint "contact_inbox_id"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.string "identifier"
    t.datetime "last_activity_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.bigint "team_id"
    t.bigint "campaign_id"
    t.datetime "snoozed_until", precision: nil
    t.jsonb "custom_attributes", default: {}
    t.datetime "assignee_last_seen_at", precision: nil
    t.datetime "first_reply_created_at", precision: nil
    t.integer "priority"
    t.bigint "sla_policy_id"
    t.datetime "waiting_since"
    t.text "cached_label_list"
    t.index ["account_id", "assignee_id"], name: "idx_conversations_assignee_account", where: "(assignee_id IS NOT NULL)"
    t.index ["account_id", "created_at", "first_reply_created_at"], name: "idx_conversations_response_time", where: "(first_reply_created_at IS NOT NULL)"
    t.index ["account_id", "display_id"], name: "index_conversations_on_account_id_and_display_id", unique: true
    t.index ["account_id", "id"], name: "index_conversations_on_id_and_account_id"
    t.index ["account_id", "inbox_id", "status", "assignee_id"], name: "conv_acid_inbid_stat_asgnid_idx"
    t.index ["account_id", "status", "updated_at", "assignee_id", "created_at"], name: "idx_conversations_multi_filter"
    t.index ["account_id", "status", "updated_at"], name: "idx_conversations_resolved_account_date", where: "(status = 1)"
    t.index ["account_id", "status"], name: "idx_conversations_active_account", where: "(status = ANY (ARRAY[0, 2]))"
    t.index ["account_id"], name: "index_conversations_on_account_id"
    t.index ["assignee_id", "account_id"], name: "index_conversations_on_assignee_id_and_account_id"
    t.index ["campaign_id"], name: "index_conversations_on_campaign_id"
    t.index ["contact_id"], name: "index_conversations_on_contact_id"
    t.index ["contact_inbox_id"], name: "index_conversations_on_contact_inbox_id"
    t.index ["first_reply_created_at"], name: "index_conversations_on_first_reply_created_at"
    t.index ["inbox_id"], name: "index_conversations_on_inbox_id"
    t.index ["priority"], name: "index_conversations_on_priority"
    t.index ["status", "account_id"], name: "index_conversations_on_status_and_account_id"
    t.index ["status", "priority"], name: "index_conversations_on_status_and_priority"
    t.index ["team_id"], name: "index_conversations_on_team_id"
    t.index ["uuid"], name: "index_conversations_on_uuid", unique: true
    t.index ["waiting_since"], name: "index_conversations_on_waiting_since"
  end

  create_table "copilot_messages", force: :cascade do |t|
    t.bigint "copilot_thread_id", null: false
    t.bigint "account_id", null: false
    t.jsonb "message", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "message_type", default: 0
    t.index ["account_id"], name: "index_copilot_messages_on_account_id"
    t.index ["copilot_thread_id"], name: "index_copilot_messages_on_copilot_thread_id"
  end

  create_table "copilot_threads", force: :cascade do |t|
    t.string "title", null: false
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "assistant_id"
    t.index ["account_id"], name: "index_copilot_threads_on_account_id"
    t.index ["assistant_id"], name: "index_copilot_threads_on_assistant_id"
    t.index ["user_id"], name: "index_copilot_threads_on_user_id"
  end

  create_table "csat_survey_responses", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "conversation_id", null: false
    t.bigint "message_id", null: false
    t.integer "rating", null: false
    t.text "feedback_message"
    t.bigint "contact_id", null: false
    t.bigint "assigned_agent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_csat_survey_responses_on_account_id"
    t.index ["assigned_agent_id"], name: "index_csat_survey_responses_on_assigned_agent_id"
    t.index ["contact_id"], name: "index_csat_survey_responses_on_contact_id"
    t.index ["conversation_id"], name: "index_csat_survey_responses_on_conversation_id"
    t.index ["message_id"], name: "index_csat_survey_responses_on_message_id", unique: true
  end

  create_table "custom_attribute_definitions", force: :cascade do |t|
    t.string "attribute_display_name"
    t.string "attribute_key"
    t.integer "attribute_display_type", default: 0
    t.integer "default_value"
    t.integer "attribute_model", default: 0
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "attribute_description"
    t.jsonb "attribute_values", default: []
    t.string "regex_pattern"
    t.string "regex_cue"
    t.index ["account_id"], name: "index_custom_attribute_definitions_on_account_id"
    t.index ["attribute_key", "attribute_model", "account_id"], name: "attribute_key_model_index", unique: true
  end

  create_table "custom_filters", force: :cascade do |t|
    t.string "name", null: false
    t.integer "filter_type", default: 0, null: false
    t.jsonb "query", default: "{}", null: false
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_custom_filters_on_account_id"
    t.index ["user_id"], name: "index_custom_filters_on_user_id"
  end

  create_table "custom_migrations", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.datetime "executed_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }

    t.unique_constraint ["name"], name: "custom_migrations_name_key"
  end

  create_table "custom_roles", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.bigint "account_id", null: false
    t.text "permissions", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_custom_roles_on_account_id"
  end

  create_table "dashboard_apps", force: :cascade do |t|
    t.string "title", null: false
    t.jsonb "content", default: []
    t.bigint "account_id", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_dashboard_apps_on_account_id"
    t.index ["user_id"], name: "index_dashboard_apps_on_user_id"
  end

  create_table "dashboard_metrics_cache", id: :serial, force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "period_type", limit: 20, null: false
    t.timestamptz "period_start", null: false
    t.timestamptz "period_end", null: false
    t.integer "total_contacts", default: 0
    t.integer "active_conversations", default: 0
    t.integer "resolved_conversations", default: 0
    t.integer "transferred_conversations", default: 0
    t.decimal "ai_resolution_rate", precision: 5, scale: 2, default: "0.0"
    t.integer "avg_response_time", default: 0
    t.integer "total_messages", default: 0
    t.integer "active_contacts", default: 0
    t.timestamptz "computed_at", default: -> { "now()" }
    t.timestamptz "expires_at", default: -> { "(now() + 'PT15M'::interval)" }
    t.index ["account_id", "period_type", "expires_at"], name: "idx_dashboard_cache_lookup"
    t.unique_constraint ["account_id", "period_type", "period_start", "period_end"], name: "dashboard_metrics_cache_account_id_period_type_period_start_key"
  end

  create_table "data_imports", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "data_type", null: false
    t.integer "status", default: 0, null: false
    t.text "processing_errors"
    t.integer "total_records"
    t.integer "processed_records"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_data_imports_on_account_id"
  end

  create_table "email_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "body", null: false
    t.integer "account_id"
    t.integer "template_type", default: 1
    t.integer "locale", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "account_id"], name: "index_email_templates_on_name_and_account_id", unique: true
  end

  create_table "failed_jobs", force: :cascade do |t|
    t.string "uuid", limit: 255, null: false
    t.text "connection", null: false
    t.text "queue", null: false
    t.text "payload", null: false
    t.text "exception", null: false
    t.datetime "failed_at", precision: 0, default: -> { "CURRENT_TIMESTAMP" }, null: false

    t.unique_constraint ["uuid"], name: "failed_jobs_uuid_unique"
  end

  create_table "folders", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "category_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inbox_assignment_policies", force: :cascade do |t|
    t.bigint "inbox_id", null: false
    t.bigint "assignment_policy_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_policy_id"], name: "index_inbox_assignment_policies_on_assignment_policy_id"
    t.index ["inbox_id"], name: "index_inbox_assignment_policies_on_inbox_id", unique: true
  end

  create_table "inbox_capacity_limits", force: :cascade do |t|
    t.bigint "agent_capacity_policy_id", null: false
    t.bigint "inbox_id", null: false
    t.integer "conversation_limit", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_capacity_policy_id", "inbox_id"], name: "idx_on_agent_capacity_policy_id_inbox_id_71c7ec4caf", unique: true
    t.index ["agent_capacity_policy_id"], name: "index_inbox_capacity_limits_on_agent_capacity_policy_id"
    t.index ["inbox_id"], name: "index_inbox_capacity_limits_on_inbox_id"
  end

  create_table "inbox_members", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "inbox_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["inbox_id", "user_id"], name: "index_inbox_members_on_inbox_id_and_user_id", unique: true
    t.index ["inbox_id"], name: "index_inbox_members_on_inbox_id"
  end

  create_table "inbox_response_sources", force: :cascade do |t|
    t.bigint "inbox_id"
    t.bigint "response_source_id"
    t.boolean "is_active", default: true
    t.integer "priority", default: 0
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "inboxes", id: :serial, force: :cascade do |t|
    t.integer "channel_id", null: false
    t.integer "account_id", null: false
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "channel_type"
    t.boolean "enable_auto_assignment", default: true
    t.boolean "greeting_enabled", default: false
    t.string "greeting_message"
    t.string "email_address"
    t.boolean "working_hours_enabled", default: false
    t.string "out_of_office_message"
    t.string "timezone", default: "UTC"
    t.boolean "enable_email_collect", default: true
    t.boolean "csat_survey_enabled", default: false
    t.boolean "allow_messages_after_resolved", default: true
    t.jsonb "auto_assignment_config", default: {}
    t.boolean "lock_to_single_conversation", default: false, null: false
    t.bigint "portal_id"
    t.integer "sender_name_type", default: 0, null: false
    t.string "business_name"
    t.string "type", limit: 50
    t.string "instanceid", limit: 100
    t.string "status", limit: 25
    t.string "serverurl", limit: 255
    t.string "number", limit: 20
    t.jsonb "additional_settings", default: {}, null: false
    t.jsonb "csat_config", default: {}, null: false
    t.index ["account_id"], name: "index_inboxes_on_account_id"
    t.index ["channel_id", "channel_type"], name: "index_inboxes_on_channel_id_and_channel_type"
    t.index ["portal_id"], name: "index_inboxes_on_portal_id"
  end

  create_table "installation_configs", force: :cascade do |t|
    t.string "name", null: false
    t.jsonb "serialized_value", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "locked", default: true, null: false
    t.index ["name", "created_at"], name: "index_installation_configs_on_name_and_created_at", unique: true
    t.index ["name"], name: "index_installation_configs_on_name", unique: true
  end

  create_table "integrations_hooks", force: :cascade do |t|
    t.integer "status", default: 1
    t.integer "inbox_id"
    t.integer "account_id"
    t.string "app_id"
    t.integer "hook_type", default: 0
    t.string "reference_id"
    t.string "access_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "settings", default: {}
  end

  create_table "knowledge_embeddings", force: :cascade do |t|
    t.bigint "knowledge_id", null: false
    t.bigint "agent_id", null: false
    t.text "content", null: false
    t.integer "chunk_index", null: false
    t.integer "word_count", default: 0
    t.vector "embedding", limit: 1536
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.index ["agent_id", "knowledge_id"], name: "idx_knowledge_embeddings_agent_knowledge"
    t.index ["agent_id"], name: "idx_knowledge_embeddings_agent_id"
    t.index ["embedding"], name: "idx_knowledge_embeddings_cosine", opclass: :vector_cosine_ops, using: :ivfflat
    t.index ["knowledge_id"], name: "idx_knowledge_embeddings_knowledge_id"
  end

  create_table "labels", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "color", default: "#1f93ff", null: false
    t.boolean "show_on_sidebar"
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_labels_on_account_id"
    t.index ["title", "account_id"], name: "index_labels_on_title_and_account_id", unique: true
  end

  create_table "leaves", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "leave_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.text "reason"
    t.bigint "approved_by_id"
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "status"], name: "index_leaves_on_account_id_and_status"
    t.index ["account_id"], name: "index_leaves_on_account_id"
    t.index ["approved_by_id"], name: "index_leaves_on_approved_by_id"
    t.index ["user_id"], name: "index_leaves_on_user_id"
  end

  create_table "macros", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.integer "visibility", default: 0
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.jsonb "actions", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_macros_on_account_id"
  end

  create_table "mentions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "conversation_id", null: false
    t.bigint "account_id", null: false
    t.datetime "mentioned_at", precision: nil, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_mentions_on_account_id"
    t.index ["conversation_id"], name: "index_mentions_on_conversation_id"
    t.index ["user_id", "conversation_id"], name: "index_mentions_on_user_id_and_conversation_id", unique: true
    t.index ["user_id"], name: "index_mentions_on_user_id"
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.text "content"
    t.integer "account_id", null: false
    t.integer "inbox_id", null: false
    t.integer "conversation_id", null: false
    t.integer "message_type", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "private", default: false, null: false
    t.integer "status", default: 0
    t.string "source_id"
    t.integer "content_type", default: 0, null: false
    t.json "content_attributes", default: {}
    t.string "sender_type"
    t.bigint "sender_id"
    t.jsonb "external_source_ids", default: {}
    t.jsonb "additional_attributes", default: {}
    t.text "processed_message_content"
    t.jsonb "sentiment", default: {}
    t.index "((additional_attributes -> 'campaign_id'::text))", name: "index_messages_on_additional_attributes_campaign_id", using: :gin
    t.index ["account_id", "content_type", "created_at"], name: "idx_messages_account_content_created"
    t.index ["account_id", "conversation_id", "sender_type", "message_type", "private"], name: "idx_messages_human_detection", where: "(((sender_type)::text = 'User'::text) AND (message_type = 1) AND (private = false))"
    t.index ["account_id", "created_at", "message_type", "private"], name: "idx_messages_account_date_type", where: "((private = false) AND (message_type = ANY (ARRAY[0, 1])))"
    t.index ["account_id", "created_at", "message_type"], name: "index_messages_on_account_created_type"
    t.index ["account_id", "inbox_id"], name: "index_messages_on_account_id_and_inbox_id"
    t.index ["account_id"], name: "index_messages_on_account_id"
    t.index ["conversation_id", "account_id", "message_type", "created_at"], name: "index_messages_on_conversation_account_type_created"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["created_at"], name: "index_messages_on_created_at"
    t.index ["inbox_id"], name: "index_messages_on_inbox_id"
    t.index ["sender_type", "sender_id"], name: "index_messages_on_sender_type_and_sender_id"
    t.index ["source_id"], name: "index_messages_on_source_id"
  end

  create_table "migrations", id: :serial, force: :cascade do |t|
    t.string "migration", limit: 255, null: false
    t.integer "batch", null: false
  end

  create_table "notes", force: :cascade do |t|
    t.text "content", null: false
    t.bigint "account_id", null: false
    t.bigint "contact_id", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_notes_on_account_id"
    t.index ["contact_id"], name: "index_notes_on_contact_id"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "notification_settings", force: :cascade do |t|
    t.integer "account_id"
    t.integer "user_id"
    t.integer "email_flags", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "push_flags", default: 0, null: false
    t.index ["account_id", "user_id"], name: "by_account_user", unique: true
  end

  create_table "notification_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "subscription_type", null: false
    t.jsonb "subscription_attributes", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "identifier"
    t.index ["identifier"], name: "index_notification_subscriptions_on_identifier", unique: true
    t.index ["user_id"], name: "index_notification_subscriptions_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.integer "notification_type", null: false
    t.string "primary_actor_type", null: false
    t.bigint "primary_actor_id", null: false
    t.string "secondary_actor_type"
    t.bigint "secondary_actor_id"
    t.datetime "read_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "snoozed_until"
    t.datetime "last_activity_at", default: -> { "CURRENT_TIMESTAMP" }
    t.jsonb "meta", default: {}
    t.index ["account_id"], name: "index_notifications_on_account_id"
    t.index ["last_activity_at"], name: "index_notifications_on_last_activity_at"
    t.index ["primary_actor_type", "primary_actor_id"], name: "uniq_primary_actor_per_account_notifications"
    t.index ["secondary_actor_type", "secondary_actor_id"], name: "uniq_secondary_actor_per_account_notifications"
    t.index ["user_id", "account_id", "snoozed_until", "read_at"], name: "idx_notifications_performance"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "nps_analytics", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "survey_id"
    t.date "period_date", null: false
    t.string "period_type", limit: 20, null: false
    t.integer "total_sent", default: 0
    t.integer "total_responses", default: 0
    t.virtual "response_rate", type: :decimal, precision: 5, scale: 2, as: "\nCASE\n    WHEN (total_sent > 0) THEN (((total_responses)::numeric / (total_sent)::numeric) * (100)::numeric)\n    ELSE (0)::numeric\nEND", stored: true
    t.integer "promoters_count", default: 0
    t.integer "passives_count", default: 0
    t.integer "detractors_count", default: 0
    t.virtual "nps_score", type: :integer, as: "\nCASE\n    WHEN (total_responses > 0) THEN (((((promoters_count)::numeric / (total_responses)::numeric) * (100)::numeric) - (((detractors_count)::numeric / (total_responses)::numeric) * (100)::numeric)))::integer\n    ELSE NULL::integer\nEND", stored: true
    t.integer "avg_response_time_seconds"
    t.jsonb "by_channel", default: {}
    t.jsonb "by_team", default: {}
    t.jsonb "by_agent", default: {}
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["account_id"], name: "idx_nps_analytics_account"
    t.index ["nps_score"], name: "idx_nps_analytics_nps_score"
    t.index ["period_date", "period_type"], name: "idx_nps_analytics_period"
    t.index ["survey_id"], name: "idx_nps_analytics_survey"
    t.unique_constraint ["account_id", "survey_id", "period_date", "period_type"], name: "nps_analytics_account_id_survey_id_period_date_period_type_key"
  end

  create_table "nps_responses", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "survey_id", null: false
    t.integer "contact_id", null: false
    t.integer "conversation_id"
    t.integer "agent_id"
    t.bigint "team_id"
    t.integer "score", null: false
    t.text "follow_up_answer"
    t.virtual "category", type: :string, limit: 20, as: "\nCASE\n    WHEN ((score >= 0) AND (score <= 6)) THEN 'detractor'::text\n    WHEN ((score >= 7) AND (score <= 8)) THEN 'passive'::text\n    WHEN ((score >= 9) AND (score <= 10)) THEN 'promoter'::text\n    ELSE NULL::text\nEND", stored: true
    t.string "channel", limit: 50, null: false
    t.timestamptz "sent_at", null: false
    t.timestamptz "responded_at", default: -> { "CURRENT_TIMESTAMP" }
    t.virtual "response_time_seconds", type: :integer, as: "(EXTRACT(epoch FROM (responded_at - sent_at)))::integer", stored: true
    t.jsonb "metadata", default: {}
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["account_id"], name: "idx_nps_responses_account_id"
    t.index ["category"], name: "idx_nps_responses_category"
    t.index ["contact_id"], name: "idx_nps_responses_contact_id"
    t.index ["created_at"], name: "idx_nps_responses_created_at"
    t.index ["score"], name: "idx_nps_responses_score"
    t.index ["survey_id"], name: "idx_nps_responses_survey_id"
    t.check_constraint "score >= 0 AND score <= 10", name: "nps_responses_score_check"
  end

  create_table "nps_scheduled_surveys", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "survey_id", null: false
    t.integer "contact_id", null: false
    t.integer "conversation_id"
    t.string "channel", limit: 50, null: false
    t.timestamptz "scheduled_for", null: false
    t.string "status", limit: 20, default: "pending", null: false
    t.integer "attempts", default: 0
    t.timestamptz "last_attempt_at"
    t.text "error_message"
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["account_id"], name: "idx_nps_scheduled_account"
    t.index ["scheduled_for"], name: "idx_nps_scheduled_for"
    t.index ["status"], name: "idx_nps_scheduled_status"
  end

  create_table "nps_surveys", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "name", limit: 255, null: false
    t.text "question", default: "De 0 a 10, qual a probabilidade de você recomendar nosso serviço para um amigo ou colega?", null: false
    t.text "follow_up_question_detractors"
    t.text "follow_up_question_passives"
    t.text "follow_up_question_promoters"
    t.string "trigger_event", limit: 100, null: false
    t.integer "trigger_delay_value", default: 0
    t.text "channels", default: [], array: true
    t.integer "target_inbox_ids", default: [], array: true
    t.integer "target_team_ids", default: [], array: true
    t.boolean "is_active", default: true
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["account_id"], name: "idx_nps_surveys_account_id"
    t.index ["is_active"], name: "idx_nps_surveys_active"
  end

  create_table "omni_account_api_keys", id: :integer, default: -> { "nextval('account_api_keys_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "provider", limit: 20, null: false
    t.text "api_key_encrypted", null: false
    t.string "api_key_name", limit: 100
    t.boolean "is_active", default: true
    t.decimal "monthly_limit_usd", precision: 10, scale: 2
    t.decimal "current_usage_usd", precision: 10, scale: 2, default: "0.0"
    t.date "usage_reset_date", default: -> { "(CURRENT_DATE + 'P1M'::interval)" }
    t.timestamptz "last_used_at"
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["account_id"], name: "idx_omni_account_api_keys_account_id"
    t.index ["is_active"], name: "idx_omni_account_api_keys_active"
    t.index ["provider"], name: "idx_omni_account_api_keys_provider"
    t.index ["usage_reset_date"], name: "idx_omni_account_api_keys_usage_reset"
    t.check_constraint "current_usage_usd >= 0::numeric", name: "chk_current_usage_positive"
    t.check_constraint "monthly_limit_usd IS NULL OR monthly_limit_usd >= 0::numeric", name: "chk_monthly_limit_positive"
    t.check_constraint "provider::text = ANY (ARRAY['openai'::character varying::text, 'anthropic'::character varying::text, 'groq'::character varying::text, 'google'::character varying::text])", name: "chk_provider_valid"
    t.unique_constraint ["account_id", "provider", "api_key_name"], name: "account_api_keys_account_id_provider_api_key_name_key"
  end

  create_table "omni_account_credit_system", id: :integer, default: -> { "nextval('account_credit_system_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "account_id", null: false
    t.boolean "use_own_keys", default: false
    t.decimal "credit_balance_usd", precision: 10, scale: 2, default: "0.0"
    t.decimal "monthly_credit_limit_usd", precision: 10, scale: 2, default: "100.0"
    t.decimal "current_month_usage_usd", precision: 10, scale: 2, default: "0.0"
    t.date "usage_reset_date", default: -> { "(CURRENT_DATE + 'P1M'::interval)" }
    t.boolean "auto_refill_enabled", default: false
    t.decimal "auto_refill_threshold_usd", precision: 10, scale: 2, default: "10.0"
    t.decimal "auto_refill_amount_usd", precision: 10, scale: 2, default: "50.0"
    t.boolean "low_balance_alert_sent", default: false
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["account_id"], name: "idx_omni_account_credit_system_account_id"
    t.index ["credit_balance_usd", "auto_refill_threshold_usd"], name: "idx_omni_account_credit_system_low_balance"
    t.index ["usage_reset_date"], name: "idx_omni_account_credit_system_usage_reset"
    t.index ["use_own_keys"], name: "idx_omni_account_credit_system_use_own_keys"
    t.check_constraint "auto_refill_amount_usd > 0::numeric", name: "chk_refill_amount_positive"
    t.check_constraint "auto_refill_threshold_usd >= 0::numeric", name: "chk_refill_threshold_positive"
    t.check_constraint "credit_balance_usd >= 0::numeric", name: "chk_credit_balance_positive"
    t.check_constraint "current_month_usage_usd >= 0::numeric", name: "chk_current_usage_positive"
    t.check_constraint "monthly_credit_limit_usd > 0::numeric", name: "chk_monthly_limit_positive"
    t.unique_constraint ["account_id"], name: "account_credit_system_account_id_key"
  end

  create_table "omni_ai_agent_conversation_stages", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.string "stage_name", limit: 255, null: false
    t.integer "stage_order", default: 1
    t.text "activation_condition"
    t.jsonb "activation_keywords", default: []
    t.text "stage_objective"
    t.text "stage_prompt"
    t.boolean "auto_advance", default: false
    t.text "next_stage_condition"
    t.boolean "is_active", default: true
    t.boolean "is_final_stage", default: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["agent_id"], name: "idx_omni_ai_agent_conversation_stages_agent"
    t.index ["stage_order"], name: "idx_omni_ai_agent_conversation_stages_order"
  end

  create_table "omni_ai_agent_conversations", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.string "contact_phone", limit: 20, null: false
    t.string "contact_name", limit: 255
    t.jsonb "conversation_context", default: {}
    t.datetime "last_message_at", precision: nil
    t.integer "message_count", default: 0
    t.string "status", limit: 20, default: "active"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.bigint "current_stage_id"
    t.jsonb "stage_history", default: []
    t.integer "lead_score", default: 0
    t.decimal "sentiment_score", precision: 3, scale: 2, default: "0.5"
    t.boolean "is_qualified", default: false
    t.text "qualification_reason"
    t.index ["agent_id"], name: "idx_omni_ai_agent_conversations_agent"
    t.index ["contact_phone"], name: "idx_omni_ai_agent_conversations_phone"
    t.index ["status"], name: "idx_omni_ai_agent_conversations_status"
  end

  create_table "omni_ai_agent_external_apis", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.string "api_name", limit: 255, null: false
    t.string "api_url", limit: 500, null: false
    t.string "api_method", limit: 10, default: "GET"
    t.string "auth_type", limit: 50, default: "none"
    t.jsonb "auth_config", default: {}
    t.jsonb "headers", default: {}
    t.jsonb "query_params", default: {}
    t.jsonb "request_body", default: {}
    t.jsonb "response_mapping", default: {}
    t.integer "cache_duration_seconds", default: 300
    t.boolean "is_active", default: true
    t.datetime "last_used_at", precision: nil
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["agent_id"], name: "idx_omni_ai_agent_external_apis_agent"
    t.index ["is_active"], name: "idx_omni_ai_agent_external_apis_active"
  end

  create_table "omni_ai_agent_faq", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.text "question", null: false
    t.text "answer", null: false
    t.jsonb "keywords", default: []
    t.string "category", limit: 100
    t.integer "priority", default: 1
    t.integer "usage_count", default: 0
    t.datetime "last_used_at", precision: nil
    t.boolean "is_active", default: true
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["agent_id"], name: "idx_omni_ai_agent_faq_agent"
    t.index ["category"], name: "idx_omni_ai_agent_faq_category"
    t.index ["priority"], name: "idx_omni_ai_agent_faq_priority"
  end

  create_table "omni_ai_agent_knowledge_base", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.string "knowledge_type", limit: 50, null: false
    t.string "title", limit: 255, null: false
    t.text "content"
    t.string "source_url", limit: 500
    t.string "file_name", limit: 255
    t.string "file_type", limit: 50
    t.integer "file_size"
    t.integer "character_count", default: 0
    t.integer "word_count", default: 0
    t.string "processing_status", limit: 50, default: "pending"
    t.integer "chunk_size", default: 1000
    t.integer "overlap_size", default: 100
    t.boolean "is_active", default: true
    t.text "processing_error"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "processed_at", precision: nil
    t.index ["agent_id"], name: "idx_omni_ai_agent_knowledge_base_agent"
    t.index ["knowledge_type"], name: "idx_omni_ai_agent_knowledge_base_type"
    t.index ["processing_status"], name: "idx_omni_ai_agent_knowledge_base_status"
  end

  create_table "omni_ai_agent_logs", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.bigint "conversation_id"
    t.string "log_type", limit: 50, null: false
    t.text "message", null: false
    t.jsonb "details"
    t.text "user_input"
    t.text "agent_response"
    t.integer "tokens_used"
    t.integer "processing_time_ms"
    t.decimal "api_cost", precision: 10, scale: 6
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["agent_id"], name: "idx_omni_ai_agent_logs_agent"
    t.index ["created_at"], name: "idx_omni_ai_agent_logs_created_at"
    t.index ["log_type"], name: "idx_omni_ai_agent_logs_type"
  end

  create_table "omni_ai_agent_messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.string "message_type", limit: 20, null: false
    t.text "content", null: false
    t.integer "tokens_used"
    t.integer "processing_time_ms"
    t.jsonb "tools_used"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["conversation_id"], name: "idx_omni_ai_agent_messages_conversation"
    t.index ["created_at"], name: "idx_omni_ai_agent_messages_created_at"
    t.index ["message_type"], name: "idx_omni_ai_agent_messages_type"
  end

  create_table "omni_ai_agent_prompt_templates", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "name", limit: 255, null: false
    t.text "description"
    t.string "category", limit: 100
    t.text "system_prompt", null: false
    t.text "welcome_message"
    t.text "fallback_message"
    t.string "recommended_model", limit: 100
    t.decimal "recommended_temperature", precision: 3, scale: 2
    t.integer "recommended_max_tokens"
    t.boolean "is_public", default: false
    t.boolean "is_system_template", default: false
    t.integer "created_by", null: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["account_id"], name: "idx_omni_ai_agent_prompt_templates_account"
    t.index ["category"], name: "idx_omni_ai_agent_prompt_templates_category"
    t.index ["is_public"], name: "idx_omni_ai_agent_prompt_templates_public"
  end

  create_table "omni_ai_agent_tool_assignments", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.bigint "tool_id", null: false
    t.boolean "is_enabled", default: true
    t.jsonb "custom_config"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["agent_id"], name: "idx_omni_ai_agent_tool_assignments_agent"
    t.index ["tool_id"], name: "idx_omni_ai_agent_tool_assignments_tool"
    t.unique_constraint ["agent_id", "tool_id"], name: "omni_ai_agent_tool_assignments_unique"
  end

  create_table "omni_ai_agent_tools", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "name", limit: 255, null: false
    t.text "description"
    t.string "tool_type", limit: 50, null: false
    t.jsonb "config", null: false
    t.jsonb "input_schema"
    t.jsonb "output_schema"
    t.boolean "is_system_tool", default: false
    t.boolean "is_public", default: false
    t.integer "created_by", null: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.index ["account_id"], name: "idx_omni_ai_agent_tools_account_id"
    t.index ["is_public"], name: "idx_omni_ai_agent_tools_public"
    t.index ["tool_type"], name: "idx_omni_ai_agent_tools_type"
  end

  create_table "omni_ai_agents", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "name", limit: 255, null: false
    t.text "description"
    t.string "avatar_url", limit: 500
    t.string "model_provider", limit: 50, default: "openai", null: false
    t.string "model_name", limit: 100, default: "gpt-4", null: false
    t.decimal "temperature", precision: 3, scale: 2, default: "0.7"
    t.integer "max_tokens", default: 1000
    t.text "system_prompt", null: false
    t.text "welcome_message"
    t.text "fallback_message", default: "Desculpe, não consegui entender. Pode reformular sua pergunta?"
    t.integer "max_conversation_history", default: 10
    t.integer "response_timeout_seconds", default: 30
    t.boolean "enable_tools", default: true
    t.boolean "enable_memory", default: true
    t.string "whatsapp_instance_id", limit: 100
    t.boolean "auto_respond", default: true
    t.time "working_hours_start", default: "2000-01-01 08:00:00"
    t.time "working_hours_end", default: "2000-01-01 18:00:00"
    t.string "working_days", limit: 20, default: "1,2,3,4,5"
    t.string "status", limit: 20, default: "active"
    t.boolean "is_published", default: false
    t.integer "created_by", null: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.string "voice_tone", limit: 50, default: "formal"
    t.string "company_name", limit: 255
    t.text "company_description"
    t.text "company_context"
    t.string "transfer_type", limit: 50, default: "platform"
    t.jsonb "transfer_conditions", default: {}
    t.text "transfer_message"
    t.string "notification_phone", limit: 20
    t.text "notification_message"
    t.boolean "enable_sentiment_analysis", default: true
    t.boolean "enable_lead_qualification", default: true
    t.boolean "auto_transfer_qualified", default: false
    t.boolean "auto_transfer_negative", default: false
    t.integer "max_file_size_mb", default: 100
    t.integer "max_files_per_upload", default: 10
    t.integer "knowledge_base_char_count", default: 0
    t.integer "knowledge_base_max_chars", default: 1000000
    t.jsonb "api_endpoints", default: []
    t.string "webhook_url", limit: 500
    t.string "webhook_secret", limit: 255
    t.decimal "credit_cost_per_message", precision: 10, scale: 6, default: "0.001"
    t.integer "monthly_credit_limit", default: 10000
    t.integer "credits_used_current_month", default: 0
    t.string "brand_color", limit: 7, default: "#6366f1"
    t.string "brand_logo_url", limit: 500
    t.text "custom_css"
    t.index ["account_id"], name: "idx_omni_ai_agents_account_id"
    t.index ["status"], name: "idx_omni_ai_agents_status"
    t.index ["whatsapp_instance_id"], name: "idx_omni_ai_agents_whatsapp_instance"
  end

  create_table "omni_campaign_blacklist", id: :serial, comment: "Phone numbers that should not receive campaigns", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "phone_number", limit: 50, null: false
    t.string "reason", limit: 255
    t.integer "added_by"
    t.timestamptz "expires_at"
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["account_id", "phone_number"], name: "idx_omni_blacklist_unique", unique: true
    t.index ["account_id"], name: "idx_omni_blacklist_account_id"
    t.index ["expires_at"], name: "idx_omni_blacklist_expires"
    t.index ["phone_number"], name: "idx_omni_blacklist_phone"
  end

  create_table "omni_campaign_contacts", id: :serial, comment: "Contacts for each campaign with validation and sending status", force: :cascade do |t|
    t.integer "campaign_id", null: false
    t.integer "contact_id"
    t.string "phone_number", limit: 50, null: false
    t.string "formatted_phone", limit: 50
    t.string "name", limit: 255
    t.string "email", limit: 255
    t.jsonb "custom_data", default: {}, comment: "Extra columns from CSV/Excel import stored as JSON"
    t.jsonb "template_variables", default: {}, comment: "Personalized template variables for this contact"
    t.string "status", limit: 50, default: "pending"
    t.string "validation_status", limit: 50
    t.string "validation_method", limit: 50
    t.string "validation_reason", limit: 100
    t.text "validation_error"
    t.timestamptz "validated_at"
    t.timestamptz "queued_at"
    t.timestamptz "sent_at"
    t.timestamptz "delivered_at"
    t.timestamptz "read_at"
    t.timestamptz "failed_at"
    t.string "error_code", limit: 50
    t.text "error_message"
    t.integer "retry_count", default: 0
    t.string "waba_message_id", limit: 255
    t.decimal "cost", precision: 10, scale: 4, default: "0.0"
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["campaign_id", "phone_number"], name: "idx_omni_campaign_contacts_unique", unique: true
    t.index ["campaign_id"], name: "idx_omni_campaign_contacts_campaign_id"
    t.index ["contact_id"], name: "idx_omni_campaign_contacts_contact_id"
    t.index ["phone_number"], name: "idx_omni_campaign_contacts_phone_number"
    t.index ["sent_at"], name: "idx_omni_campaign_contacts_sent_at"
    t.index ["status"], name: "idx_omni_campaign_contacts_status"
    t.index ["waba_message_id"], name: "idx_omni_campaign_contacts_waba_message_id"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'validating'::character varying::text, 'valid'::character varying::text, 'invalid'::character varying::text, 'queued'::character varying::text, 'sending'::character varying::text, 'sent'::character varying::text, 'delivered'::character varying::text, 'read'::character varying::text, 'failed'::character varying::text, 'blocked'::character varying::text, 'opted_out'::character varying::text, 'skipped'::character varying::text])", name: "omni_campaign_contacts_status_check"
  end

  create_table "omni_campaign_messages", id: :serial, comment: "Detailed message tracking with Meta API responses", force: :cascade do |t|
    t.integer "campaign_id", null: false
    t.integer "campaign_contact_id", null: false
    t.string "template_name", limit: 255, null: false
    t.string "template_language", limit: 10, default: "pt_BR"
    t.jsonb "template_params", default: {}
    t.string "message_type", limit: 50, default: "template"
    t.string "message_status", limit: 50
    t.jsonb "meta_request"
    t.jsonb "meta_response"
    t.jsonb "webhook_events", default: [], comment: "Array of all webhook events received for this message"
    t.string "conversation_id", limit: 255
    t.string "pricing_model", limit: 50
    t.decimal "cost", precision: 10, scale: 4, default: "0.0"
    t.string "currency", limit: 10, default: "BRL"
    t.timestamptz "sent_at"
    t.timestamptz "delivered_at"
    t.timestamptz "read_at"
    t.timestamptz "failed_at"
    t.string "error_code", limit: 50
    t.text "error_message"
    t.jsonb "error_details"
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.string "waba_message_id", limit: 255, comment: "WhatsApp Business API message ID from Meta (extracted from meta_response for easier webhook correlation)"
    t.index ["campaign_contact_id"], name: "idx_omni_campaign_messages_contact_id"
    t.index ["campaign_id"], name: "idx_omni_campaign_messages_campaign_id"
    t.index ["conversation_id"], name: "idx_omni_campaign_messages_conversation_id"
    t.index ["message_status"], name: "idx_omni_campaign_messages_status"
    t.index ["sent_at"], name: "idx_omni_campaign_messages_sent_at", order: :desc
    t.index ["waba_message_id"], name: "idx_omni_campaign_messages_waba_message_id"
    t.check_constraint "message_type::text = ANY (ARRAY['template'::character varying::text, 'text'::character varying::text, 'media'::character varying::text])", name: "omni_campaign_messages_message_type_check"
  end

  create_table "omni_campaign_queue", id: :serial, comment: "Message queue for scheduled and throttled sending", force: :cascade do |t|
    t.integer "campaign_id", null: false
    t.integer "campaign_contact_id", null: false
    t.integer "priority", default: 5, comment: "Priority 1-10, where 1 is highest priority"
    t.timestamptz "scheduled_for", null: false
    t.integer "attempts", default: 0
    t.integer "max_attempts", default: 3
    t.string "status", limit: 50, default: "pending"
    t.timestamptz "locked_at"
    t.string "locked_by", limit: 255
    t.timestamptz "processed_at"
    t.text "error_message"
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["campaign_contact_id"], name: "idx_omni_queue_contact_id"
    t.index ["campaign_id"], name: "idx_omni_queue_campaign_id"
    t.index ["locked_at"], name: "idx_omni_queue_locked", where: "(locked_at IS NOT NULL)"
    t.index ["status", "scheduled_for"], name: "idx_omni_queue_status_scheduled", where: "((status)::text = 'pending'::text)"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'processing'::character varying::text, 'completed'::character varying::text, 'failed'::character varying::text])", name: "omni_campaign_queue_status_check"
  end

  create_table "omni_campaign_tags", id: :serial, comment: "Tags associated with campaigns for segmentation", force: :cascade do |t|
    t.integer "campaign_id", null: false
    t.integer "tag_id", null: false
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["campaign_id", "tag_id"], name: "idx_omni_campaign_tags_unique", unique: true
    t.index ["campaign_id"], name: "idx_omni_campaign_tags_campaign_id"
    t.index ["tag_id"], name: "idx_omni_campaign_tags_tag_id"
  end

  create_table "omni_campaign_webhook_logs", id: :serial, comment: "Raw webhook events from Meta for debugging", force: :cascade do |t|
    t.integer "campaign_id"
    t.string "waba_message_id", limit: 255
    t.string "phone_number", limit: 50
    t.string "event_type", limit: 100
    t.timestamptz "event_timestamp"
    t.jsonb "payload", null: false
    t.boolean "processed", default: false
    t.timestamptz "processed_at"
    t.text "error_message"
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["campaign_id"], name: "idx_omni_webhook_logs_campaign_id"
    t.index ["created_at"], name: "idx_omni_webhook_logs_created_at", order: :desc
    t.index ["event_type"], name: "idx_omni_webhook_logs_event_type"
    t.index ["phone_number"], name: "idx_omni_webhook_logs_phone"
    t.index ["processed"], name: "idx_omni_webhook_logs_processed"
    t.index ["waba_message_id"], name: "idx_omni_webhook_logs_message_id"
  end

  create_table "omni_campaigns", id: :serial, comment: "Main campaigns table for WhatsApp Business API campaigns", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "name", limit: 255, null: false
    t.text "description"
    t.integer "template_id"
    t.string "template_name", limit: 255
    t.string "template_language", limit: 10, default: "pt_BR"
    t.string "status", limit: 50, default: "draft"
    t.timestamptz "scheduled_at"
    t.timestamptz "started_at"
    t.timestamptz "completed_at"
    t.timestamptz "cancelled_at"
    t.string "source_type", limit: 50, default: "contacts"
    t.text "source_file_url"
    t.string "source_file_name", limit: 255
    t.jsonb "filters", default: {}
    t.jsonb "template_params", default: []
    t.jsonb "settings", default: {"rateLimit" => 80, "retryDelay" => 300000, "retryAttempts" => 3, "blacklistCheck" => true, "validateNumbers" => "auto", "requireEvolutionValidation" => false}
    t.jsonb "statistics", default: {"cost" => 0, "read" => 0, "sent" => 0, "total" => 0, "failed" => 0, "invalid" => 0, "delivered" => 0, "validated" => 0}, comment: "Real-time campaign statistics updated by trigger"
    t.integer "created_by"
    t.integer "updated_by"
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["account_id"], name: "idx_omni_campaigns_account_id"
    t.index ["created_at"], name: "idx_omni_campaigns_created_at", order: :desc
    t.index ["scheduled_at"], name: "idx_omni_campaigns_scheduled_at"
    t.index ["status"], name: "idx_omni_campaigns_status"
    t.index ["template_id"], name: "idx_omni_campaigns_template_id"
    t.check_constraint "source_type::text = ANY (ARRAY['csv'::character varying::text, 'excel'::character varying::text, 'contacts'::character varying::text, 'tags'::character varying::text, 'mixed'::character varying::text])", name: "omni_campaigns_source_type_check"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying::text, 'scheduled'::character varying::text, 'running'::character varying::text, 'paused'::character varying::text, 'completed'::character varying::text, 'failed'::character varying::text, 'cancelled'::character varying::text])", name: "omni_campaigns_status_check"
  end

  create_table "omni_credit_transactions", id: :integer, default: -> { "nextval('credit_transactions_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "transaction_type", limit: 20, null: false
    t.decimal "amount_usd", precision: 10, scale: 2, null: false
    t.decimal "balance_before_usd", precision: 10, scale: 2, null: false
    t.decimal "balance_after_usd", precision: 10, scale: 2, null: false
    t.integer "usage_log_id"
    t.string "provider", limit: 20
    t.string "model_name", limit: 100
    t.integer "tokens_used"
    t.string "payment_method", limit: 50
    t.string "payment_id", limit: 255
    t.text "description"
    t.jsonb "metadata", default: {}
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["account_id"], name: "idx_omni_credit_transactions_account_id"
    t.index ["created_at"], name: "idx_omni_credit_transactions_created_at"
    t.index ["transaction_type"], name: "idx_omni_credit_transactions_type"
    t.index ["usage_log_id"], name: "idx_omni_credit_transactions_usage_log_id"
    t.check_constraint "balance_before_usd >= 0::numeric AND balance_after_usd >= 0::numeric", name: "chk_balance_positive"
    t.check_constraint "tokens_used IS NULL OR tokens_used >= 0", name: "chk_tokens_positive"
    t.check_constraint "transaction_type::text = ANY (ARRAY['purchase'::character varying::text, 'usage'::character varying::text, 'refund'::character varying::text, 'bonus'::character varying::text])", name: "chk_transaction_type_valid"
  end

  create_table "omni_llm_usage_logs", id: :integer, default: -> { "nextval('llm_usage_logs_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "account_id", null: false
    t.bigint "agent_id"
    t.string "provider", limit: 20, null: false
    t.string "model_name", limit: 100, null: false
    t.string "usage_type", limit: 20, null: false
    t.integer "api_key_id"
    t.integer "prompt_tokens", null: false
    t.integer "completion_tokens", null: false
    t.integer "total_tokens", null: false
    t.decimal "cost_usd", precision: 10, scale: 4, null: false
    t.string "conversation_id", limit: 255
    t.integer "message_content_length"
    t.integer "response_time_ms"
    t.boolean "success", default: true
    t.text "error_message"
    t.string "request_id", limit: 100
    t.jsonb "metadata", default: {}
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["account_id"], name: "idx_omni_llm_usage_logs_account_id"
    t.index ["agent_id"], name: "idx_omni_llm_usage_logs_agent_id"
    t.index ["api_key_id"], name: "idx_omni_llm_usage_logs_api_key_id"
    t.index ["created_at"], name: "idx_omni_llm_usage_logs_created_at"
    t.index ["provider"], name: "idx_omni_llm_usage_logs_provider"
    t.index ["usage_type"], name: "idx_omni_llm_usage_logs_usage_type"
    t.check_constraint "cost_usd >= 0::numeric", name: "chk_cost_positive"
    t.check_constraint "prompt_tokens >= 0 AND completion_tokens >= 0 AND total_tokens >= 0", name: "chk_tokens_positive"
    t.check_constraint "provider::text = ANY (ARRAY['openai'::character varying::text, 'anthropic'::character varying::text, 'groq'::character varying::text, 'google'::character varying::text])", name: "chk_provider_valid"
    t.check_constraint "usage_type::text = ANY (ARRAY['own_key'::character varying::text, 'platform_credits'::character varying::text])", name: "chk_usage_type_valid"
  end

  create_table "omni_whatsapp_agent_mapping", force: :cascade do |t|
    t.integer "account_id", null: false
    t.text "instance_id", null: false
    t.bigint "agent_id", null: false
    t.boolean "auto_respond", default: true
    t.boolean "transfer_on_complex", default: false
    t.integer "max_auto_responses", default: 5
    t.boolean "business_hours_only", default: false
    t.text "allowed_numbers", array: true
    t.text "blocked_numbers", array: true
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
    t.integer "created_by"
    t.index ["account_id"], name: "idx_whatsapp_agent_mapping_account_id"
    t.index ["agent_id"], name: "idx_whatsapp_agent_mapping_agent_id"
    t.index ["instance_id"], name: "idx_whatsapp_agent_mapping_instance_id"
    t.unique_constraint ["instance_id"], name: "omni_whatsapp_agent_mapping_instance_id_key"
  end

  create_table "omni_whatsapp_conversations", force: :cascade do |t|
    t.integer "account_id", null: false
    t.text "instance_id", null: false
    t.bigint "agent_id", null: false
    t.text "whatsapp_jid", null: false
    t.text "conversation_key", null: false
    t.text "message_id"
    t.text "message_content", null: false
    t.string "message_type", limit: 50, default: "text"
    t.string "message_direction", limit: 20, null: false
    t.boolean "processed_by_ai", default: false
    t.text "ai_response"
    t.decimal "ai_confidence", precision: 5, scale: 2
    t.boolean "should_transfer", default: false
    t.integer "processing_time_ms"
    t.text "from_name"
    t.text "from_number"
    t.jsonb "webhook_data"
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.index ["account_id"], name: "idx_whatsapp_conversations_account_id"
    t.index ["agent_id"], name: "idx_whatsapp_conversations_agent_id"
    t.index ["created_at"], name: "idx_whatsapp_conversations_created_at", order: :desc
    t.index ["instance_id"], name: "idx_whatsapp_conversations_instance_id"
    t.index ["whatsapp_jid"], name: "idx_whatsapp_conversations_jid"
  end

  create_table "password_reset_tokens", primary_key: "email", id: { type: :string, limit: 255 }, force: :cascade do |t|
    t.string "token", limit: 255, null: false
    t.datetime "created_at", precision: 0
  end

  create_table "personal_access_tokens", force: :cascade do |t|
    t.string "tokenable_type", limit: 255, null: false
    t.bigint "tokenable_id", null: false
    t.string "name", limit: 255, null: false
    t.string "token", limit: 64, null: false
    t.text "abilities"
    t.datetime "last_used_at", precision: 0
    t.datetime "expires_at", precision: 0
    t.datetime "created_at", precision: 0
    t.datetime "updated_at", precision: 0
    t.index ["tokenable_type", "tokenable_id"], name: "personal_access_tokens_tokenable_type_tokenable_id_index"
    t.unique_constraint ["token"], name: "personal_access_tokens_token_unique"
  end

  create_table "plans", id: :uuid, default: nil, force: :cascade do |t|
    t.datetime "created_at", precision: 0
    t.datetime "updated_at", precision: 0
    t.string "name", limit: 100, null: false
    t.text "description"
    t.decimal "value", precision: 12, scale: 2
    t.boolean "active", default: true, null: false
    t.boolean "most_purchased", default: false, null: false
  end

  create_table "platform_app_permissibles", force: :cascade do |t|
    t.bigint "platform_app_id", null: false
    t.string "permissible_type", null: false
    t.bigint "permissible_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permissible_type", "permissible_id"], name: "index_platform_app_permissibles_on_permissibles"
    t.index ["platform_app_id", "permissible_id", "permissible_type"], name: "unique_permissibles_index", unique: true
    t.index ["platform_app_id"], name: "index_platform_app_permissibles_on_platform_app_id"
  end

  create_table "platform_apps", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "portals", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "custom_domain"
    t.string "color"
    t.string "homepage_link"
    t.string "page_title"
    t.text "header_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "config", default: {"allowed_locales" => ["en"]}
    t.boolean "archived", default: false
    t.bigint "channel_web_widget_id"
    t.jsonb "ssl_settings", default: {}, null: false
    t.index ["channel_web_widget_id"], name: "index_portals_on_channel_web_widget_id"
    t.index ["custom_domain"], name: "index_portals_on_custom_domain", unique: true
    t.index ["slug"], name: "index_portals_on_slug", unique: true
  end

  create_table "portals_members", id: false, force: :cascade do |t|
    t.bigint "portal_id", null: false
    t.bigint "user_id", null: false
    t.index ["portal_id", "user_id"], name: "index_portals_members_on_portal_id_and_user_id", unique: true
    t.index ["portal_id"], name: "index_portals_members_on_portal_id"
    t.index ["user_id"], name: "index_portals_members_on_user_id"
  end

  create_table "related_categories", force: :cascade do |t|
    t.bigint "category_id"
    t.bigint "related_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "related_category_id"], name: "index_related_categories_on_category_id_and_related_category_id", unique: true
    t.index ["related_category_id", "category_id"], name: "index_related_categories_on_related_category_id_and_category_id", unique: true
  end

  create_table "reporting_events", force: :cascade do |t|
    t.string "name"
    t.float "value"
    t.integer "account_id"
    t.integer "inbox_id"
    t.integer "user_id"
    t.integer "conversation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "value_in_business_hours"
    t.datetime "event_start_time", precision: nil
    t.datetime "event_end_time", precision: nil
    t.index ["account_id", "name", "created_at"], name: "reporting_events__account_id__name__created_at"
    t.index ["account_id"], name: "index_reporting_events_on_account_id"
    t.index ["conversation_id"], name: "index_reporting_events_on_conversation_id"
    t.index ["created_at"], name: "index_reporting_events_on_created_at"
    t.index ["inbox_id"], name: "index_reporting_events_on_inbox_id"
    t.index ["name"], name: "index_reporting_events_on_name"
    t.index ["user_id"], name: "index_reporting_events_on_user_id"
  end

  create_table "response_documents", force: :cascade do |t|
    t.bigint "response_source_id"
    t.string "title", limit: 255
    t.text "content"
    t.string "document_type", limit: 100
    t.text "file_url"
    t.jsonb "metadata", default: {}
    t.string "status", limit: 50, default: "processed"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "response_sources", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "source_type", limit: 100, null: false
    t.text "source_url"
    t.bigint "account_id"
    t.string "status", limit: 50, default: "active"
    t.jsonb "configuration", default: {}
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "responses", force: :cascade do |t|
    t.text "content"
    t.bigint "account_id"
    t.bigint "user_id"
    t.bigint "conversation_id"
    t.string "status", limit: 50, default: "draft"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "sla_events", force: :cascade do |t|
    t.bigint "applied_sla_id", null: false
    t.bigint "conversation_id", null: false
    t.bigint "account_id", null: false
    t.bigint "sla_policy_id", null: false
    t.bigint "inbox_id", null: false
    t.integer "event_type"
    t.jsonb "meta", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_sla_events_on_account_id"
    t.index ["applied_sla_id"], name: "index_sla_events_on_applied_sla_id"
    t.index ["conversation_id"], name: "index_sla_events_on_conversation_id"
    t.index ["inbox_id"], name: "index_sla_events_on_inbox_id"
    t.index ["sla_policy_id"], name: "index_sla_events_on_sla_policy_id"
  end

  create_table "sla_policies", force: :cascade do |t|
    t.string "name", null: false
    t.float "first_response_time_threshold"
    t.float "next_response_time_threshold"
    t.boolean "only_during_business_hours", default: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.float "resolution_time_threshold"
    t.index ["account_id"], name: "index_sla_policies_on_account_id"
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "team_members", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["team_id", "user_id"], name: "index_team_members_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_members_on_team_id"
    t.index ["user_id"], name: "index_team_members_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "allow_auto_assign", default: true
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_teams_on_account_id"
    t.index ["name", "account_id"], name: "index_teams_on_name_and_account_id", unique: true
  end

  create_table "template_sync_logs", id: :serial, force: :cascade do |t|
    t.integer "cadence_template_id", null: false
    t.integer "whatsapp_config_id", null: false
    t.string "sync_type", limit: 20, null: false
    t.string "sync_status", limit: 20, null: false
    t.jsonb "request_data"
    t.jsonb "response_data"
    t.text "error_message"
    t.string "error_code", limit: 50
    t.string "api_version", limit: 10, default: "v18.0"
    t.integer "execution_time_ms"
    t.integer "retry_count", default: 0
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "completed_at", precision: nil
    t.index ["cadence_template_id", "sync_status", "created_at"], name: "idx_sync_logs_template_status", order: { created_at: :desc }
    t.index ["cadence_template_id"], name: "idx_sync_logs_template"
    t.index ["created_at"], name: "idx_sync_logs_cleanup", where: "((sync_status)::text = ANY (ARRAY[('success'::character varying)::text, ('error'::character varying)::text]))"
    t.index ["created_at"], name: "idx_sync_logs_created_at"
    t.index ["sync_status"], name: "idx_sync_logs_status"
    t.index ["sync_type"], name: "idx_sync_logs_type"
    t.index ["whatsapp_config_id"], name: "idx_sync_logs_config"
    t.check_constraint "sync_status::text = ANY (ARRAY['success'::character varying::text, 'error'::character varying::text, 'pending'::character varying::text, 'timeout'::character varying::text])", name: "template_sync_logs_sync_status_check"
    t.check_constraint "sync_type::text = ANY (ARRAY['create'::character varying::text, 'update'::character varying::text, 'delete'::character varying::text, 'status_check'::character varying::text, 'quality_update'::character varying::text])", name: "template_sync_logs_sync_type_check"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.string "name", null: false
    t.string "display_name"
    t.string "email"
    t.json "tokens"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "pubsub_token"
    t.integer "availability", default: 0
    t.jsonb "ui_settings", default: {}
    t.jsonb "custom_attributes", default: {}
    t.string "type"
    t.text "message_signature"
    t.string "otp_secret"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login", default: false, null: false
    t.text "otp_backup_codes"
    t.index ["email"], name: "index_users_on_email"
    t.index ["otp_required_for_login"], name: "index_users_on_otp_required_for_login"
    t.index ["otp_secret"], name: "index_users_on_otp_secret", unique: true
    t.index ["pubsub_token"], name: "index_users_on_pubsub_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  create_table "webhooks", force: :cascade do |t|
    t.integer "account_id"
    t.integer "inbox_id"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "webhook_type", default: 0
    t.jsonb "subscriptions", default: ["conversation_status_changed", "conversation_updated", "conversation_created", "contact_created", "contact_updated", "message_created", "message_updated", "webwidget_triggered"]
    t.index ["account_id", "url"], name: "index_webhooks_on_account_id_and_url", unique: true
  end

  create_table "whatsapp_business_configs", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "business_account_id", limit: 255
    t.string "app_id", limit: 255, null: false
    t.text "access_token", null: false
    t.string "waba_id", limit: 255, null: false
    t.string "waba_name", limit: 255
    t.string "message_template_namespace", limit: 255
    t.string "business_phone_number_id", limit: 255, null: false
    t.string "display_phone_number", limit: 20
    t.string "phone_number_name", limit: 255
    t.string "api_version", limit: 10, default: "v18.0"
    t.string "webhook_url", limit: 500
    t.string "webhook_verify_token", limit: 255
    t.string "status", limit: 20, default: "active"
    t.datetime "last_sync_at", precision: nil
    t.text "sync_error"
    t.integer "daily_conversations_quota", default: 1000
    t.integer "daily_conversations_used", default: 0
    t.datetime "quota_reset_at", precision: nil, default: -> { "(CURRENT_DATE + 'P1D'::interval)" }
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.string "verified_name", limit: 255, comment: "WhatsApp Business verified name from Meta API"
    t.string "quality_rating", limit: 20, default: "UNKNOWN", comment: "WhatsApp quality rating: GREEN, YELLOW, RED, UNKNOWN"
    t.string "phone_number", limit: 20, comment: "Full phone number with country code from Meta API"
    t.string "waba_currency", limit: 10, comment: "Currency code (e.g., BRL, USD) from Meta API"
    t.string "waba_timezone", limit: 50, comment: "Timezone ID from Meta API"
    t.string "namespace", limit: 255
    t.string "business_portfolio_id", limit: 255, comment: "Meta Business Portfolio ID from Embedded Signup"
    t.integer "created_by", comment: "User ID who created this config"
    t.integer "updated_by", comment: "User ID who last updated this config"
    t.index ["account_id"], name: "idx_whatsapp_configs_account_id"
    t.index ["business_phone_number_id"], name: "idx_whatsapp_configs_phone_id"
    t.index ["business_portfolio_id"], name: "idx_whatsapp_configs_business_portfolio"
    t.index ["created_at"], name: "idx_whatsapp_configs_created_at"
    t.index ["created_by"], name: "idx_whatsapp_configs_created_by"
    t.index ["phone_number"], name: "idx_whatsapp_configs_phone_number"
    t.index ["quality_rating"], name: "idx_whatsapp_configs_quality_rating"
    t.index ["status"], name: "idx_whatsapp_configs_status"
    t.index ["updated_by"], name: "idx_whatsapp_configs_updated_by"
    t.index ["verified_name"], name: "idx_whatsapp_configs_verified_name"
    t.index ["waba_id"], name: "idx_whatsapp_configs_waba_id"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying::text, 'inactive'::character varying::text, 'error'::character varying::text, 'suspended'::character varying::text])", name: "whatsapp_business_configs_status_check"
    t.unique_constraint ["account_id", "waba_id"], name: "uk_whatsapp_configs_account_waba"
    t.unique_constraint ["business_phone_number_id"], name: "uk_whatsapp_configs_phone_number"
  end

  create_table "whatsapp_instances", id: :text, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "account_id", null: false
    t.text "instance_name", null: false
    t.text "instance_id"
    t.text "apikey"
    t.text "status", default: "disconnected", null: false
    t.text "number"
    t.text "qrcode"
    t.text "webhook_url"
    t.integer "chatwoot_inbox_id"
    t.jsonb "settings", default: {}
    t.datetime "created_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 3, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "whatsapp_instances_account_id_idx"
    t.index ["instance_id"], name: "whatsapp_instances_instance_id_key", unique: true
    t.index ["instance_name"], name: "whatsapp_instances_instance_name_key", unique: true
  end

  create_table "working_hours", force: :cascade do |t|
    t.bigint "inbox_id"
    t.bigint "account_id"
    t.integer "day_of_week", null: false
    t.boolean "closed_all_day", default: false
    t.integer "open_hour"
    t.integer "open_minutes"
    t.integer "close_hour"
    t.integer "close_minutes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "open_all_day", default: false
    t.index ["account_id"], name: "index_working_hours_on_account_id"
    t.index ["inbox_id"], name: "index_working_hours_on_inbox_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cadence_activity_logs", "accounts", name: "cadence_activity_logs_account_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cadence_activity_logs", "cadence_executions", name: "cadence_activity_logs_cadence_execution_id_fkey", on_update: :cascade, on_delete: :nullify
  add_foreign_key "cadence_activity_logs", "contacts", name: "cadence_activity_logs_contact_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cadence_executions", "accounts", name: "cadence_executions_account_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cadence_executions", "cadence_flows", name: "cadence_executions_cadence_flow_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cadence_executions", "channel_whatsapp", name: "cadence_executions_channel_whatsapp_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cadence_executions", "contacts", name: "cadence_executions_contact_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cadence_flows", "accounts", name: "cadence_flows_account_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cadence_interactions", "cadence_executions", name: "cadence_interactions_cadence_execution_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cadence_interactions", "contacts", name: "cadence_interactions_contact_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cadence_messages", "cadence_executions", name: "cadence_messages_cadence_execution_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cadence_messages", "cadence_steps", name: "cadence_messages_cadence_step_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cadence_messages", "contacts", name: "cadence_messages_contact_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cadence_qualification_configs", "accounts", name: "cadence_qualification_configs_account_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cadence_steps", "cadence_flows", name: "cadence_steps_cadence_flow_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cadence_templates", "accounts", name: "cadence_templates_account_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "cadence_templates", "whatsapp_business_configs", column: "whatsapp_config_id", name: "fk_cadence_templates_whatsapp_config", on_delete: :nullify
  add_foreign_key "cobrowse_session_events", "cobrowse_sessions", column: "session_id", name: "cobrowse_session_events_session_id_fkey", on_delete: :cascade
  add_foreign_key "cobrowse_sessions", "accounts", name: "cobrowse_sessions_account_id_fkey", on_delete: :cascade
  add_foreign_key "cobrowse_sessions", "contacts", name: "cobrowse_sessions_contact_id_fkey", on_delete: :nullify
  add_foreign_key "cobrowse_sessions", "conversations", name: "cobrowse_sessions_conversation_id_fkey", on_delete: :nullify
  add_foreign_key "cobrowse_sessions", "users", column: "agent_id", name: "cobrowse_sessions_agent_id_fkey", on_delete: :cascade
  add_foreign_key "contact_qualifications", "accounts", name: "contact_qualifications_account_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "contact_qualifications", "contacts", name: "contact_qualifications_contact_id_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "inbox_response_sources", "inboxes", name: "inbox_response_sources_inbox_id_fkey", on_delete: :cascade
  add_foreign_key "inbox_response_sources", "response_sources", name: "inbox_response_sources_response_source_id_fkey", on_delete: :cascade
  add_foreign_key "inboxes", "portals"
  add_foreign_key "knowledge_embeddings", "omni_ai_agent_knowledge_base", column: "knowledge_id", name: "fk_knowledge_embeddings_knowledge_id", on_delete: :cascade
  add_foreign_key "knowledge_embeddings", "omni_ai_agents", column: "agent_id", name: "fk_knowledge_embeddings_agent_id", on_delete: :cascade
  add_foreign_key "nps_analytics", "accounts", name: "nps_analytics_account_id_fkey", on_delete: :cascade
  add_foreign_key "nps_analytics", "nps_surveys", column: "survey_id", name: "nps_analytics_survey_id_fkey", on_delete: :cascade
  add_foreign_key "nps_responses", "accounts", name: "nps_responses_account_id_fkey", on_delete: :cascade
  add_foreign_key "nps_responses", "contacts", name: "nps_responses_contact_id_fkey", on_delete: :cascade
  add_foreign_key "nps_responses", "conversations", name: "nps_responses_conversation_id_fkey", on_delete: :nullify
  add_foreign_key "nps_responses", "nps_surveys", column: "survey_id", name: "nps_responses_survey_id_fkey", on_delete: :cascade
  add_foreign_key "nps_responses", "teams", name: "nps_responses_team_id_fkey", on_delete: :nullify
  add_foreign_key "nps_responses", "users", column: "agent_id", name: "nps_responses_agent_id_fkey", on_delete: :nullify
  add_foreign_key "nps_scheduled_surveys", "accounts", name: "nps_scheduled_surveys_account_id_fkey", on_delete: :cascade
  add_foreign_key "nps_scheduled_surveys", "contacts", name: "nps_scheduled_surveys_contact_id_fkey", on_delete: :cascade
  add_foreign_key "nps_scheduled_surveys", "conversations", name: "nps_scheduled_surveys_conversation_id_fkey", on_delete: :nullify
  add_foreign_key "nps_scheduled_surveys", "nps_surveys", column: "survey_id", name: "nps_scheduled_surveys_survey_id_fkey", on_delete: :cascade
  add_foreign_key "nps_surveys", "accounts", name: "nps_surveys_account_id_fkey", on_delete: :cascade
  add_foreign_key "omni_account_api_keys", "accounts", name: "account_api_keys_account_id_fkey", on_delete: :cascade
  add_foreign_key "omni_account_credit_system", "accounts", name: "account_credit_system_account_id_fkey", on_delete: :cascade
  add_foreign_key "omni_ai_agent_conversation_stages", "omni_ai_agents", column: "agent_id", name: "omni_ai_agent_conversation_stages_agent_fk", on_delete: :cascade
  add_foreign_key "omni_ai_agent_conversations", "omni_ai_agent_conversation_stages", column: "current_stage_id", name: "omni_ai_agent_conversations_stage_fk", on_delete: :nullify
  add_foreign_key "omni_ai_agent_conversations", "omni_ai_agents", column: "agent_id", name: "omni_ai_agent_conversations_agent_fk", on_delete: :cascade
  add_foreign_key "omni_ai_agent_external_apis", "omni_ai_agents", column: "agent_id", name: "omni_ai_agent_external_apis_agent_fk", on_delete: :cascade
  add_foreign_key "omni_ai_agent_faq", "omni_ai_agents", column: "agent_id", name: "omni_ai_agent_faq_agent_fk", on_delete: :cascade
  add_foreign_key "omni_ai_agent_knowledge_base", "omni_ai_agents", column: "agent_id", name: "omni_ai_agent_knowledge_base_agent_fk", on_delete: :cascade
  add_foreign_key "omni_ai_agent_logs", "omni_ai_agent_conversations", column: "conversation_id", name: "omni_ai_agent_logs_conversation_fk", on_delete: :cascade
  add_foreign_key "omni_ai_agent_logs", "omni_ai_agents", column: "agent_id", name: "omni_ai_agent_logs_agent_fk", on_delete: :cascade
  add_foreign_key "omni_ai_agent_messages", "omni_ai_agent_conversations", column: "conversation_id", name: "omni_ai_agent_messages_conversation_fk", on_delete: :cascade
  add_foreign_key "omni_ai_agent_prompt_templates", "accounts", name: "omni_ai_agent_prompt_templates_account_fk"
  add_foreign_key "omni_ai_agent_prompt_templates", "users", column: "created_by", name: "omni_ai_agent_prompt_templates_created_by_fk"
  add_foreign_key "omni_ai_agent_tool_assignments", "omni_ai_agent_tools", column: "tool_id", name: "omni_ai_agent_tool_assignments_tool_fk", on_delete: :cascade
  add_foreign_key "omni_ai_agent_tool_assignments", "omni_ai_agents", column: "agent_id", name: "omni_ai_agent_tool_assignments_agent_fk", on_delete: :cascade
  add_foreign_key "omni_ai_agent_tools", "accounts", name: "omni_ai_agent_tools_account_fk"
  add_foreign_key "omni_ai_agent_tools", "users", column: "created_by", name: "omni_ai_agent_tools_created_by_fk"
  add_foreign_key "omni_ai_agents", "accounts", name: "omni_ai_agents_account_fk"
  add_foreign_key "omni_ai_agents", "users", column: "created_by", name: "omni_ai_agents_created_by_fk"
  add_foreign_key "omni_campaign_blacklist", "accounts", name: "omni_campaign_blacklist_account_id_fkey", on_delete: :cascade
  add_foreign_key "omni_campaign_blacklist", "users", column: "added_by", name: "omni_campaign_blacklist_added_by_fkey"
  add_foreign_key "omni_campaign_contacts", "contacts", name: "omni_campaign_contacts_contact_id_fkey", on_delete: :nullify
  add_foreign_key "omni_campaign_contacts", "omni_campaigns", column: "campaign_id", name: "omni_campaign_contacts_campaign_id_fkey", on_delete: :cascade
  add_foreign_key "omni_campaign_messages", "omni_campaign_contacts", column: "campaign_contact_id", name: "omni_campaign_messages_campaign_contact_id_fkey", on_delete: :cascade
  add_foreign_key "omni_campaign_messages", "omni_campaigns", column: "campaign_id", name: "omni_campaign_messages_campaign_id_fkey", on_delete: :cascade
  add_foreign_key "omni_campaign_queue", "omni_campaign_contacts", column: "campaign_contact_id", name: "omni_campaign_queue_campaign_contact_id_fkey", on_delete: :cascade
  add_foreign_key "omni_campaign_queue", "omni_campaigns", column: "campaign_id", name: "omni_campaign_queue_campaign_id_fkey", on_delete: :cascade
  add_foreign_key "omni_campaign_tags", "omni_campaigns", column: "campaign_id", name: "omni_campaign_tags_campaign_id_fkey", on_delete: :cascade
  add_foreign_key "omni_campaign_tags", "tags", name: "omni_campaign_tags_tag_id_fkey", on_delete: :cascade
  add_foreign_key "omni_campaign_webhook_logs", "omni_campaigns", column: "campaign_id", name: "omni_campaign_webhook_logs_campaign_id_fkey", on_delete: :cascade
  add_foreign_key "omni_campaigns", "accounts", name: "omni_campaigns_account_id_fkey", on_delete: :cascade
  add_foreign_key "omni_campaigns", "cadence_templates", column: "template_id", name: "omni_campaigns_template_id_fkey"
  add_foreign_key "omni_campaigns", "users", column: "created_by", name: "omni_campaigns_created_by_fkey"
  add_foreign_key "omni_campaigns", "users", column: "updated_by", name: "omni_campaigns_updated_by_fkey"
  add_foreign_key "omni_credit_transactions", "accounts", name: "credit_transactions_account_id_fkey", on_delete: :cascade
  add_foreign_key "omni_credit_transactions", "omni_llm_usage_logs", column: "usage_log_id", name: "omni_credit_transactions_usage_log_id_fkey", on_delete: :nullify
  add_foreign_key "omni_llm_usage_logs", "accounts", name: "llm_usage_logs_account_id_fkey", on_delete: :cascade
  add_foreign_key "omni_llm_usage_logs", "omni_account_api_keys", column: "api_key_id", name: "omni_llm_usage_logs_api_key_id_fkey", on_delete: :nullify
  add_foreign_key "omni_llm_usage_logs", "omni_ai_agents", column: "agent_id", name: "llm_usage_logs_agent_id_fkey", on_delete: :nullify
  add_foreign_key "omni_whatsapp_agent_mapping", "accounts", name: "omni_whatsapp_agent_mapping_account_id_fkey", on_delete: :cascade
  add_foreign_key "omni_whatsapp_agent_mapping", "omni_ai_agents", column: "agent_id", name: "omni_whatsapp_agent_mapping_agent_id_fkey", on_delete: :cascade
  add_foreign_key "omni_whatsapp_agent_mapping", "whatsapp_instances", column: "instance_id", name: "omni_whatsapp_agent_mapping_instance_id_fkey", on_delete: :cascade
  add_foreign_key "omni_whatsapp_conversations", "accounts", name: "omni_whatsapp_conversations_account_id_fkey", on_delete: :cascade
  add_foreign_key "omni_whatsapp_conversations", "omni_ai_agents", column: "agent_id", name: "omni_whatsapp_conversations_agent_id_fkey", on_delete: :cascade
  add_foreign_key "omni_whatsapp_conversations", "whatsapp_instances", column: "instance_id", name: "omni_whatsapp_conversations_instance_id_fkey", on_delete: :cascade
  add_foreign_key "response_documents", "response_sources", name: "response_documents_response_source_id_fkey", on_delete: :cascade
  add_foreign_key "response_sources", "accounts", name: "response_sources_account_id_fkey"
  add_foreign_key "responses", "accounts", name: "responses_account_id_fkey"
  add_foreign_key "responses", "conversations", name: "responses_conversation_id_fkey"
  add_foreign_key "responses", "users", name: "responses_user_id_fkey"
  add_foreign_key "template_sync_logs", "cadence_templates", name: "fk_sync_logs_template", on_delete: :cascade
  add_foreign_key "template_sync_logs", "whatsapp_business_configs", column: "whatsapp_config_id", name: "fk_sync_logs_whatsapp_config", on_delete: :cascade
  add_foreign_key "whatsapp_business_configs", "accounts", name: "fk_whatsapp_configs_account", on_delete: :cascade
  add_foreign_key "whatsapp_business_configs", "users", column: "created_by", name: "whatsapp_business_configs_created_by_fkey"
  add_foreign_key "whatsapp_business_configs", "users", column: "updated_by", name: "whatsapp_business_configs_updated_by_fkey"
  add_foreign_key "whatsapp_instances", "accounts", name: "whatsapp_instances_account_id_fkey", on_update: :cascade, on_delete: :restrict
  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER trg_update_nps_analytics AFTER INSERT ON \"nps_responses\" FOR EACH ROW EXECUTE FUNCTION update_nps_analytics()")

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER trigger_update_campaign_stats AFTER INSERT OR DELETE OR UPDATE OF status, cost ON omni_campaign_contacts FOR EACH ROW EXECUTE FUNCTION update_campaign_statistics()")

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER trigger_update_whatsapp_agent_mapping_updated_at BEFORE UPDATE ON \"omni_whatsapp_agent_mapping\" FOR EACH ROW EXECUTE FUNCTION update_whatsapp_agent_mapping_updated_at()")

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER trigger_whatsapp_configs_updated_at BEFORE UPDATE ON \"whatsapp_business_configs\" FOR EACH ROW EXECUTE FUNCTION update_whatsapp_configs_updated_at()")

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER update_cadence_flows_updated_at BEFORE UPDATE ON \"cadence_flows\" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()")

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER update_cadence_messages_updated_at BEFORE UPDATE ON \"cadence_messages\" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()")

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER update_cadence_qualification_configs_updated_at BEFORE UPDATE ON \"cadence_qualification_configs\" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()")

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER update_cadence_steps_updated_at BEFORE UPDATE ON \"cadence_steps\" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()")

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER update_cadence_templates_updated_at BEFORE UPDATE ON \"cadence_templates\" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()")

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute(<<-SQL)
CREATE OR REPLACE FUNCTION public.update_campaign_statistics()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    
    UPDATE omni_campaigns
    SET statistics = (
        SELECT jsonb_build_object(
            'total', COUNT(*),
            'validated', COUNT(*) FILTER (WHERE status = 'valid'),
            'invalid', COUNT(*) FILTER (WHERE status = 'invalid'),
            'sent', COUNT(*) FILTER (WHERE status = 'sent'),
            'delivered', COUNT(*) FILTER (WHERE status = 'delivered'),
            'read', COUNT(*) FILTER (WHERE status = 'read'),
            'failed', COUNT(*) FILTER (WHERE status = 'failed'),
            'cost', COALESCE(SUM(cost), 0)
        )
        FROM omni_campaign_contacts
        WHERE campaign_id = COALESCE(NEW.campaign_id, OLD.campaign_id)
    ),
    updated_at = CURRENT_TIMESTAMP
    WHERE id = COALESCE(NEW.campaign_id, OLD.campaign_id);
    
    RETURN NEW;
END;
$function$
  SQL

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute(<<-SQL)
CREATE OR REPLACE FUNCTION public.update_nps_analytics()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
        
        INSERT INTO nps_analytics (
            account_id, survey_id, period_date, period_type,
            total_responses, promoters_count, passives_count, detractors_count
        )
        VALUES (
            NEW.account_id, NEW.survey_id, DATE(NEW.created_at), 'daily',
            1,
            CASE WHEN NEW.category = 'promoter' THEN 1 ELSE 0 END,
            CASE WHEN NEW.category = 'passive' THEN 1 ELSE 0 END,
            CASE WHEN NEW.category = 'detractor' THEN 1 ELSE 0 END
        )
        ON CONFLICT (account_id, survey_id, period_date, period_type) DO UPDATE
        SET 
            total_responses = nps_analytics.total_responses + 1,
            promoters_count = nps_analytics.promoters_count + CASE WHEN NEW.category = 'promoter' THEN 1 ELSE 0 END,
            passives_count = nps_analytics.passives_count + CASE WHEN NEW.category = 'passive' THEN 1 ELSE 0 END,
            detractors_count = nps_analytics.detractors_count + CASE WHEN NEW.category = 'detractor' THEN 1 ELSE 0 END,
            updated_at = CURRENT_TIMESTAMP;

        RETURN NEW;
    END;
    $function$
  SQL

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER update_omni_campaign_contacts_updated_at BEFORE UPDATE ON \"omni_campaign_contacts\" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()")

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER update_omni_campaign_messages_updated_at BEFORE UPDATE ON \"omni_campaign_messages\" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()")

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER update_omni_campaign_queue_updated_at BEFORE UPDATE ON \"omni_campaign_queue\" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()")

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER update_omni_campaigns_updated_at BEFORE UPDATE ON \"omni_campaigns\" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()")

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute(<<-SQL)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
  SQL

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute(<<-SQL)
CREATE OR REPLACE FUNCTION public.update_whatsapp_agent_mapping_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
  SQL

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute(<<-SQL)
CREATE OR REPLACE FUNCTION public.update_whatsapp_configs_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
  SQL

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute(<<-SQL)
CREATE OR REPLACE FUNCTION public.update_whatsapp_instances_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
  SQL

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER update_whatsapp_instances_updated_at BEFORE UPDATE ON \"whatsapp_instances\" FOR EACH ROW EXECUTE FUNCTION update_whatsapp_instances_updated_at()")

  create_trigger("accounts_after_insert_row_tr", :generated => true, :compatibility => 1).
      on("accounts").
      after(:insert).
      for_each(:row) do
    "execute format('create sequence IF NOT EXISTS conv_dpid_seq_%s', NEW.id);"
  end

  create_trigger("conversations_before_insert_row_tr", :generated => true, :compatibility => 1).
      on("conversations").
      before(:insert).
      for_each(:row) do
    "NEW.display_id := nextval('conv_dpid_seq_' || NEW.account_id);"
  end

  create_trigger("camp_dpid_before_insert", :generated => true, :compatibility => 1).
      on("accounts").
      name("camp_dpid_before_insert").
      after(:insert).
      for_each(:row) do
    "execute format('create sequence IF NOT EXISTS camp_dpid_seq_%s', NEW.id);"
  end

  create_trigger("campaigns_before_insert_row_tr", :generated => true, :compatibility => 1).
      on("campaigns").
      before(:insert).
      for_each(:row) do
    "NEW.display_id := nextval('camp_dpid_seq_' || NEW.account_id);"
  end

end
