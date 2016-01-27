# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20151217233823) do

  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",       null: false
    t.string   "document_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type"
    t.string   "document_type"
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id"

  create_table "bulk_action_messages", force: :cascade do |t|
    t.string   "message"
    t.string   "druid"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "bulk_action_statuses_id"
  end

  add_index "bulk_action_messages", ["bulk_action_statuses_id"], name: "index_bulk_action_messages_on_bulk_action_statuses_id"

  create_table "bulk_action_statuses", force: :cascade do |t|
    t.boolean  "success"
    t.boolean  "completed"
    t.boolean  "started"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "bulk_actions_id"
  end

  add_index "bulk_action_statuses", ["bulk_actions_id"], name: "index_bulk_action_statuses_on_bulk_actions_id"

  create_table "bulk_actions", force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "bulk_actionable_id"
    t.string   "bulk_actionable_type"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "user_id"
  end

  add_index "bulk_actions", ["bulk_actionable_id", "bulk_actionable_type"], name: "bulk_actionable_index"
  add_index "bulk_actions", ["user_id"], name: "index_bulk_actions_on_user_id"

  create_table "bulk_descmetadata_downloads", force: :cascade do |t|
    t.string   "filename"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "indexing_exceptions", force: :cascade do |t|
    t.string   "pid"
    t.text     "solr_document"
    t.string   "dor_services_version"
    t.text     "exception"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "indexing_exceptions", ["pid"], name: "index_indexing_exceptions_on_pid"

  create_table "searches", force: :cascade do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type"
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id"

  create_table "users", force: :cascade do |t|
    t.string   "sunetid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "wfs_rails_workflows", force: :cascade do |t|
    t.string   "druid",                                                  null: false
    t.string   "datastream",                                             null: false
    t.string   "process",                                                null: false
    t.string   "status"
    t.text     "error_msg"
    t.binary   "error_txt"
    t.integer  "attempts",                           default: 0,         null: false
    t.string   "lifecycle"
    t.decimal  "elapsed",    precision: 9, scale: 3
    t.string   "repository"
    t.integer  "version",                            default: 1
    t.text     "note"
    t.integer  "priority",                           default: 0
    t.string   "lane_id",                            default: "default", null: false
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
  end

end
