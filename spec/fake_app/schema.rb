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

ActiveRecord::Schema[8.0].define(version: 0) do
  create_table "addresses", force: :cascade do |t|
  end

  create_table "adjustments", force: :cascade do |t|
  end

  create_table "admin_users", force: :cascade do |t|
  end

  create_table "assets", force: :cascade do |t|
  end

  create_table "calculators", force: :cascade do |t|
  end

  create_table "classifications", force: :cascade do |t|
  end

  create_table "cms_pages", force: :cascade do |t|
  end

  create_table "cms_sections", force: :cascade do |t|
  end

  create_table "countries", force: :cascade do |t|
  end

  create_table "coupon_codes", force: :cascade do |t|
  end

  create_table "credit_cards", force: :cascade do |t|
  end

  create_table "customer_returns", force: :cascade do |t|
  end

  create_table "data_feeds", force: :cascade do |t|
  end

  create_table "digital_links", force: :cascade do |t|
  end

  create_table "digitals", force: :cascade do |t|
  end

  create_table "exports", force: :cascade do |t|
  end

  create_table "inventory_units", force: :cascade do |t|
  end

  create_table "legacy_users", force: :cascade do |t|
  end

  create_table "line_items", force: :cascade do |t|
  end

  create_table "log_entries", force: :cascade do |t|
  end

  create_table "menu_items", force: :cascade do |t|
  end

  create_table "menus", force: :cascade do |t|
  end

  create_table "oauth_access_grants", force: :cascade do |t|
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
  end

  create_table "oauth_applications", force: :cascade do |t|
  end

  create_table "option_type_prototypes", force: :cascade do |t|
  end

  create_table "option_types", force: :cascade do |t|
  end

  create_table "option_value_variants", force: :cascade do |t|
  end

  create_table "option_values", force: :cascade do |t|
  end

  create_table "order_promotions", force: :cascade do |t|
  end

  create_table "orders", force: :cascade do |t|
  end

  create_table "payment_capture_events", force: :cascade do |t|
  end

  create_table "payment_methods", force: :cascade do |t|
  end

  create_table "payment_sources", force: :cascade do |t|
  end

  create_table "payments", force: :cascade do |t|
  end

  create_table "preferences", force: :cascade do |t|
  end

  create_table "prices", force: :cascade do |t|
  end

  create_table "product_option_types", force: :cascade do |t|
  end

  create_table "product_promotion_rules", force: :cascade do |t|
  end

  create_table "product_properties", force: :cascade do |t|
  end

  create_table "products", force: :cascade do |t|
  end

  create_table "promotion_action_line_items", force: :cascade do |t|
  end

  create_table "promotion_actions", force: :cascade do |t|
  end

  create_table "promotion_categories", force: :cascade do |t|
  end

  create_table "promotion_rule_taxons", force: :cascade do |t|
  end

  create_table "promotion_rule_users", force: :cascade do |t|
  end

  create_table "promotion_rules", force: :cascade do |t|
  end

  create_table "promotions", force: :cascade do |t|
  end

  create_table "properties", force: :cascade do |t|
  end

  create_table "property_prototypes", force: :cascade do |t|
  end

  create_table "prototype_taxons", force: :cascade do |t|
  end

  create_table "prototypes", force: :cascade do |t|
  end

  create_table "refund_reasons", force: :cascade do |t|
  end

  create_table "refunds", force: :cascade do |t|
  end

  create_table "reimbursement_types", force: :cascade do |t|
  end

  create_table "reimbursements", force: :cascade do |t|
  end

  create_table "return_authorization_reasons", force: :cascade do |t|
  end

  create_table "return_authorizations", force: :cascade do |t|
  end

  create_table "return_items", force: :cascade do |t|
  end

  create_table "role_users", force: :cascade do |t|
  end

  create_table "roles", force: :cascade do |t|
  end

  create_table "shipments", force: :cascade do |t|
  end

  create_table "shipping_categories", force: :cascade do |t|
  end

  create_table "shipping_method_categories", force: :cascade do |t|
  end

  create_table "shipping_method_zones", force: :cascade do |t|
  end

  create_table "shipping_methods", force: :cascade do |t|
  end

  create_table "shipping_rates", force: :cascade do |t|
  end

  create_table "state_changes", force: :cascade do |t|
  end

  create_table "states", force: :cascade do |t|
  end

  create_table "stock_items", force: :cascade do |t|
  end

  create_table "stock_locations", force: :cascade do |t|
  end

  create_table "stock_movements", force: :cascade do |t|
  end

  create_table "stock_transfers", force: :cascade do |t|
  end

  create_table "store_credit_categories", force: :cascade do |t|
  end

  create_table "store_credit_events", force: :cascade do |t|
  end

  create_table "store_credit_types", force: :cascade do |t|
  end

  create_table "store_credits", force: :cascade do |t|
  end

  create_table "store_payment_methods", force: :cascade do |t|
  end

  create_table "store_products", force: :cascade do |t|
  end

  create_table "store_promotions", force: :cascade do |t|
  end

  create_table "stores", force: :cascade do |t|
  end

  create_table "tax_categories", force: :cascade do |t|
  end

  create_table "tax_rates", force: :cascade do |t|
  end

  create_table "taxon_rules", force: :cascade do |t|
  end

  create_table "taxonomies", force: :cascade do |t|
  end

  create_table "taxons", force: :cascade do |t|
  end

  create_table "users", force: :cascade do |t|
  end

  create_table "variants", force: :cascade do |t|
  end

  create_table "wished_items", force: :cascade do |t|
  end

  create_table "wishlists", force: :cascade do |t|
  end

  create_table "zone_members", force: :cascade do |t|
  end

  create_table "zones", force: :cascade do |t|
  end
end
