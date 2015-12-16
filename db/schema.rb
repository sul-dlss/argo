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

ActiveRecord::Schema.define(version: 20151112054510) do

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

  create_table "robots", force: :cascade do |t|
    t.string   "wf"
    t.string   "process"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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
