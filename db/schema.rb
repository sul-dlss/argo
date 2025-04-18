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

ActiveRecord::Schema[7.2].define(version: 2024_08_01_155124) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bookmarks", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "document_id"
    t.string "title"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "user_type"
    t.string "document_type"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "bulk_actions", id: :serial, force: :cascade do |t|
    t.string "action_type"
    t.string "status"
    t.string "log_name"
    t.string "description"
    t.integer "druid_count_total", default: 0
    t.integer "druid_count_success", default: 0
    t.integer "druid_count_fail", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_bulk_actions_on_user_id"
  end

  create_table "indexing_exceptions", id: :serial, force: :cascade do |t|
    t.string "pid"
    t.text "solr_document"
    t.string "dor_services_version"
    t.text "exception"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["pid"], name: "index_indexing_exceptions_on_pid"
  end

  create_table "searches", id: :serial, force: :cascade do |t|
    t.text "query_params"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "user_type"
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "sunetid"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end
end
