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

ActiveRecord::Schema[8.0].define(version: 2026_09_26_042507) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "appeals", force: :cascade do |t|
    t.bigint "submitting_member_id", null: false
    t.bigint "event_id", null: false
    t.string "appeal_type"
    t.text "reason"
    t.string "status"
    t.bigint "reviewed_by_member_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_appeals_on_event_id"
    t.index ["reviewed_by_member_id"], name: "index_appeals_on_reviewed_by_member_id"
    t.index ["submitting_member_id"], name: "index_appeals_on_submitting_member_id"
  end

  create_table "attendances", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.bigint "event_id", null: false
    t.datetime "check_in_time"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["member_id", "event_id"], name: "index_attendances_on_member_id_and_event_id", unique: true
    t.index ["member_id"], name: "index_attendances_on_member_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "category_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "events", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "semester_id", null: false
    t.string "event_name"
    t.datetime "event_date_time"
    t.decimal "point_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_events_on_category_id"
    t.index ["semester_id"], name: "index_events_on_semester_id"
  end

  create_table "members", force: :cascade do |t|
    t.integer "uin"
    t.string "tamu_email"
    t.string "name"
    t.integer "class_year"
    t.boolean "is_admin", default: false, null: false
    t.string "standing"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "semester_requirements", force: :cascade do |t|
    t.bigint "semester_id", null: false
    t.bigint "category_id", null: false
    t.integer "required_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_semester_requirements_on_category_id"
    t.index ["semester_id"], name: "index_semester_requirements_on_semester_id"
  end

  create_table "semesters", force: :cascade do |t|
    t.string "term_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uid"
    t.string "provider"
    t.string "full_name"
    t.string "avatar_url"
  end

  add_foreign_key "appeals", "events"
  add_foreign_key "appeals", "members", column: "reviewed_by_member_id"
  add_foreign_key "appeals", "members", column: "submitting_member_id"
  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "members"
  add_foreign_key "events", "categories"
  add_foreign_key "events", "semesters"
  add_foreign_key "members", "users"
  add_foreign_key "semester_requirements", "categories"
  add_foreign_key "semester_requirements", "semesters"
end
