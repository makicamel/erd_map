# frozen_string_literal: true

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require "rails"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.fixture_path = "#{Rails.root}/spec/fixtures"
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
