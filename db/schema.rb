# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_04_06_023300) do

  create_table "bookmarks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "document_id"
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "user_type"
    t.string "document_type"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "bulk_actions", force: :cascade do |t|
    t.string "action_type"
    t.string "status"
    t.string "log_name"
    t.string "description"
    t.integer "druid_count_total", default: 0
    t.integer "druid_count_success", default: 0
    t.integer "druid_count_fail", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_bulk_actions_on_user_id"
  end

  create_table "indexing_exceptions", force: :cascade do |t|
    t.string "pid"
    t.text "solr_document"
    t.string "dor_services_version"
    t.text "exception"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["pid"], name: "index_indexing_exceptions_on_pid"
  end

  create_table "searches", force: :cascade do |t|
    t.text "query_params"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "user_type"
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "sunetid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
