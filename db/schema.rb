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

ActiveRecord::Schema[8.0].define(version: 2026_03_10_210642) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "street"
    t.string "postal_code"
    t.string "city"
    t.string "country"
    t.string "vat_id"
    t.string "email"
    t.string "phone"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country_code"
    t.string "tax_id"
    t.string "buyer_reference"
    t.string "contact_name"
    t.string "payment_terms"
    t.text "notes"
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.integer "position"
    t.string "description"
    t.text "detail"
    t.decimal "quantity"
    t.string "unit_code"
    t.decimal "unit_price"
    t.decimal "line_net_amount"
    t.decimal "tax_rate"
    t.string "tax_category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "customer_id", null: false
    t.string "number"
    t.string "document_type"
    t.date "issue_date"
    t.date "due_date"
    t.date "delivery_date"
    t.date "payment_date"
    t.string "status"
    t.string "zugferd_profile"
    t.string "currency_code"
    t.decimal "tax_rate"
    t.string "tax_category"
    t.decimal "tax_amount"
    t.decimal "net_amount"
    t.decimal "gross_amount"
    t.string "payment_terms"
    t.string "payment_means_code"
    t.string "order_reference"
    t.string "contract_reference"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "seller_id", null: false
    t.string "project_number"
    t.string "project_manager"
    t.string "production_location"
    t.text "intro_text"
    t.date "service_period_end"
    t.string "project_title"
    t.index ["customer_id"], name: "index_invoices_on_customer_id"
    t.index ["seller_id"], name: "index_invoices_on_seller_id"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "sellers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.string "street"
    t.string "city"
    t.string "postal_code"
    t.string "country_code"
    t.string "email"
    t.string "phone"
    t.string "tax_id"
    t.string "vat_id"
    t.string "iban"
    t.string "bic"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sellers_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_name"
    t.string "role"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "customers", "users"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoices", "customers"
  add_foreign_key "invoices", "sellers"
  add_foreign_key "invoices", "users"
  add_foreign_key "sellers", "users"
end
