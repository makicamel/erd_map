# frozen_string_literal: true

class CreateAllTables < ActiveRecord::Migration[7.0]
  def self.up
    create_table 'addresses' do |t|
    end

    create_table 'adjustments' do |t|
    end

    create_table 'admin_users' do |t|
    end

    create_table 'assets' do |t|
    end

    create_table 'calculators' do |t|
    end

    create_table 'classifications' do |t|
    end

    create_table 'cms_pages' do |t|
    end

    create_table 'cms_sections' do |t|
    end

    create_table 'countries' do |t|
    end

    create_table 'coupon_codes' do |t|
    end

    create_table 'credit_cards' do |t|
    end

    create_table 'customer_returns' do |t|
    end

    create_table 'data_feeds' do |t|
    end

    create_table 'digital_links' do |t|
    end

    create_table 'digitals' do |t|
    end

    create_table 'exports' do |t|
    end

    create_table 'inventory_units' do |t|
    end

    create_table 'legacy_users' do |t|
    end

    create_table 'line_items' do |t|
    end

    create_table 'log_entries' do |t|
    end

    create_table 'menu_items' do |t|
    end

    create_table 'menus' do |t|
    end

    create_table 'oauth_access_grants' do |t|
    end

    create_table 'oauth_access_tokens' do |t|
    end

    create_table 'oauth_applications' do |t|
    end

    create_table 'option_type_prototypes' do |t|
    end

    create_table 'option_types' do |t|
    end

    create_table 'option_value_variants' do |t|
    end

    create_table 'option_values' do |t|
    end

    create_table 'order_promotions' do |t|
    end

    create_table 'orders' do |t|
    end

    create_table 'payment_capture_events' do |t|
    end

    create_table 'payment_methods' do |t|
    end

    create_table 'payment_sources' do |t|
    end

    create_table 'payments' do |t|
    end

    create_table 'preferences' do |t|
    end

    create_table 'prices' do |t|
    end

    create_table 'product_option_types' do |t|
    end

    create_table 'product_promotion_rules' do |t|
    end

    create_table 'product_properties' do |t|
    end

    create_table 'products' do |t|
    end

    create_table 'promotion_action_line_items' do |t|
    end

    create_table 'promotion_actions' do |t|
    end

    create_table 'promotion_categories' do |t|
    end

    create_table 'promotion_rule_taxons' do |t|
    end

    create_table 'promotion_rule_users' do |t|
    end

    create_table 'promotion_rules' do |t|
    end

    create_table 'promotions' do |t|
    end

    create_table 'properties' do |t|
    end

    create_table 'property_prototypes' do |t|
    end

    create_table 'prototype_taxons' do |t|
    end

    create_table 'prototypes' do |t|
    end

    create_table 'refund_reasons' do |t|
    end

    create_table 'refunds' do |t|
    end

    create_table 'reimbursement_types' do |t|
    end

    create_table 'reimbursements' do |t|
    end

    create_table 'return_authorization_reasons' do |t|
    end

    create_table 'return_authorizations' do |t|
    end

    create_table 'return_items' do |t|
    end

    create_table 'role_users' do |t|
    end

    create_table 'roles' do |t|
    end

    create_table 'shipments' do |t|
    end

    create_table 'shipping_categories' do |t|
    end

    create_table 'shipping_method_categories' do |t|
    end

    create_table 'shipping_method_zones' do |t|
    end

    create_table 'shipping_methods' do |t|
    end

    create_table 'shipping_rates' do |t|
    end

    create_table 'state_changes' do |t|
    end

    create_table 'states' do |t|
    end

    create_table 'stock_items' do |t|
    end

    create_table 'stock_locations' do |t|
    end

    create_table 'stock_movements' do |t|
    end

    create_table 'stock_transfers' do |t|
    end

    create_table 'store_credit_categories' do |t|
    end

    create_table 'store_credit_events' do |t|
    end

    create_table 'store_credit_types' do |t|
    end

    create_table 'store_credits' do |t|
    end

    create_table 'store_payment_methods' do |t|
    end

    create_table 'store_products' do |t|
    end

    create_table 'store_promotions' do |t|
    end

    create_table 'stores' do |t|
    end

    create_table 'tax_categories' do |t|
    end

    create_table 'tax_rates' do |t|
    end

    create_table 'taxon_rules' do |t|
    end

    create_table 'taxonomies' do |t|
    end

    create_table 'taxons' do |t|
    end

    create_table 'users' do |t|
    end

    create_table 'variants' do |t|
    end

    create_table 'wished_items' do |t|
    end

    create_table 'wishlists' do |t|
    end

    create_table 'zone_members' do |t|
    end

    create_table 'zones' do |t|
    end
  end
end

CreateAllTables.up
