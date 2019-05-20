# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_05_19_234300) do

  create_table "activation_calls", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "gift_card_id"
    t.string "sid"
    t.text "transcript", limit: 16777215
    t.string "audio_url"
    t.string "call_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "call_status", default: "created"
    t.string "token"
    t.index ["gift_card_id"], name: "index_activation_calls_on_gift_card_id"
    t.index ["token"], name: "index_activation_calls_on_token", unique: true
  end

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "budgets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "USD", null: false
    t.integer "team_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_budgets_on_team_id"
  end

  create_table "carts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", default: "default"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description", limit: 16777215
    t.integer "people_count", default: 0
    t.string "rapidpro_uuid"
    t.boolean "rapidpro_sync", default: false
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "carts_people", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "person_id", null: false
    t.index ["cart_id", "person_id"], name: "index_carts_people_on_cart_id_and_person_id"
    t.index ["cart_id"], name: "index_carts_people_on_cart_id"
    t.index ["person_id", "cart_id"], name: "index_carts_people_on_person_id_and_cart_id"
    t.index ["person_id"], name: "index_carts_people_on_person_id"
  end

  create_table "carts_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "user_id", null: false
    t.boolean "current_cart", default: false
    t.index ["cart_id", "user_id"], name: "index_carts_users_on_cart_id_and_user_id"
    t.index ["cart_id"], name: "index_carts_users_on_cart_id"
    t.index ["user_id", "cart_id"], name: "index_carts_users_on_user_id_and_cart_id"
    t.index ["user_id"], name: "index_carts_users_on_user_id"
  end

  create_table "cash_cards", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "USD", null: false
    t.string "notes"
    t.integer "reward_id"
    t.integer "person_id"
    t.integer "created_by", null: false
    t.integer "user_id"
    t.text "legacy_attributes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id"], name: "index_cash_cards_on_person_id"
    t.index ["user_id"], name: "index_cash_cards_on_user_id"
  end

  create_table "comments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "content"
    t.integer "user_id"
    t.string "commentable_type"
    t.integer "commentable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "created_by"
    t.index ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type"
  end

  create_table "delayed_jobs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "delayed_reference_id"
    t.string "delayed_reference_type"
    t.index ["delayed_reference_type"], name: "delayed_jobs_delayed_reference_type"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
    t.index ["queue"], name: "delayed_jobs_queue"
  end

  create_table "digital_gifts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "order_details"
    t.integer "created_by", null: false
    t.integer "user_id"
    t.integer "person_id"
    t.integer "reward_id"
    t.string "giftrocket_status"
    t.string "external_id"
    t.string "order_id"
    t.string "gift_id"
    t.text "link"
    t.integer "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "USD", null: false
    t.integer "fee_cents", default: 0, null: false
    t.string "fee_currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "campaign_id"
    t.string "campaign_title"
    t.string "funding_source_id"
    t.boolean "sent"
    t.datetime "sent_at"
    t.integer "sent_by"
    t.index ["reward_id"], name: "index_digital_gifts_on_reward_id"
    t.index ["user_id"], name: "index_digital_gifts_on_user_id"
  end

  create_table "gift_cards", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "full_card_number"
    t.string "expiration_date"
    t.integer "sequence_number"
    t.string "secure_code"
    t.string "batch_id"
    t.string "status", default: "created"
    t.integer "user_id"
    t.integer "reward_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "USD", null: false
    t.integer "created_by"
    t.index ["user_id"], name: "index_gift_cards_on_user_id"
  end

  create_table "invitation_invitees_join_table", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "person_id"
    t.integer "event_invitation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invitations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "research_session_id"
    t.string "aasm_state"
    t.index ["person_id"], name: "index_invitations_on_person_id"
    t.index ["research_session_id"], name: "index_invitations_on_research_session_id"
  end

  create_table "mailchimp_exports", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.text "body"
    t.integer "created_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mailchimp_updates", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "raw_content"
    t.string "email"
    t.string "update_type"
    t.string "reason"
    t.datetime "fired_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "people", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email_address"
    t.string "address_1"
    t.string "address_2"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.integer "geography_id"
    t.integer "primary_device_id"
    t.string "primary_device_description"
    t.integer "secondary_device_id"
    t.string "secondary_device_description"
    t.integer "primary_connection_id"
    t.string "primary_connection_description"
    t.string "phone_number"
    t.string "participation_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "signup_ip"
    t.datetime "signup_at"
    t.string "voted"
    t.string "called_311"
    t.integer "secondary_connection_id"
    t.string "secondary_connection_description"
    t.string "verified"
    t.string "preferred_contact_method"
    t.string "token"
    t.boolean "active", default: true
    t.datetime "deactivated_at"
    t.string "deactivated_method"
    t.string "neighborhood"
    t.string "referred_by"
    t.boolean "low_income"
    t.string "rapidpro_uuid"
    t.string "landline"
    t.integer "created_by"
    t.string "screening_status", default: "new"
    t.boolean "phone_confirmed", default: false
    t.boolean "email_confirmed", default: false
    t.boolean "confirmation_sent", default: false
    t.boolean "welcome_sent", default: false
    t.string "participation_level", default: "new"
    t.string "locale", default: "en"
    t.text "cached_tag_list"
  end

  create_table "research_sessions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "description"
    t.integer "buffer", default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.string "title"
    t.datetime "start_datetime"
    t.datetime "end_datetime"
    t.string "sms_description"
    t.integer "session_type", default: 1
    t.string "location"
    t.integer "duration", default: 60
    t.string "cached_tag_list"
    t.index ["user_id"], name: "index_research_sessions_on_user_id"
  end

  create_table "rewards", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "person_id"
    t.string "notes"
    t.integer "created_by"
    t.integer "reason"
    t.integer "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "USD", null: false
    t.integer "giftable_id"
    t.string "giftable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "team_id"
    t.string "finance_code"
    t.integer "user_id"
    t.string "rewardable_type"
    t.bigint "rewardable_id"
    t.index ["giftable_id", "giftable_type"], name: "index_rewards_on_giftable_id_and_giftable_type"
    t.index ["giftable_type", "giftable_id"], name: "index_rewards_on_giftable_type_and_giftable_id"
    t.index ["person_id"], name: "index_rewards_on_person_id"
    t.index ["reason"], name: "gift_reason_index"
    t.index ["rewardable_id", "rewardable_type"], name: "index_rewards_on_rewardable_id_and_rewardable_type"
    t.index ["rewardable_type", "rewardable_id"], name: "index_rewards_on_rewardable_type_and_rewardable_id"
    t.index ["team_id"], name: "index_rewards_on_team_id"
    t.index ["user_id"], name: "index_rewards_on_user_id"
  end

  create_table "taggings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.integer "tagger_id"
    t.string "tagger_type"
    t.string "context", limit: 128
    t.datetime "created_at"
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

  create_table "tags", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "teams", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "finance_code"
    t.text "description", limit: 16777215
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transaction_logs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "from_id"
    t.string "from_type"
    t.integer "recipient_id"
    t.string "recipient_type"
    t.string "transaction_type"
    t.integer "user_id"
    t.integer "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_id", "from_type"], name: "index_transaction_logs_on_from_id_and_from_type"
    t.index ["recipient_id", "recipient_type"], name: "index_transaction_logs_on_recipient_id_and_recipient_type"
    t.index ["user_id"], name: "index_transaction_logs_on_user_id"
  end

  create_table "twilio_messages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "message_sid"
    t.datetime "date_created"
    t.datetime "date_updated"
    t.datetime "date_sent"
    t.string "account_sid"
    t.string "from"
    t.string "to"
    t.text "body"
    t.string "status"
    t.string "error_code"
    t.string "error_message"
    t.string "direction"
    t.string "from_city"
    t.string "from_state"
    t.string "from_zip"
    t.string "wufoo_formid"
    t.integer "conversation_count"
    t.string "signup_verify"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "password_salt"
    t.string "invitation_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "approved", default: false, null: false
    t.string "name"
    t.string "token"
    t.string "phone_number"
    t.boolean "new_person_notification", default: false
    t.bigint "team_id"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by_type_and_invited_by_id"
    t.index ["team_id"], name: "fk_rails_b2bbf87303"
  end

  create_table "versions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "item_type", limit: 191, null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", limit: 4294967295
    t.datetime "created_at"
    t.text "object_changes", limit: 4294967295
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "users", "teams"
end
