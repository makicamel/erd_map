# frozen_string_literal: true

require "active_record/railtie"
require "erd_map"

require_relative "fake_app/config/environment"
require_relative "fake_app/db/00000000000000_create_all_tables"
ActiveRecord::Tasks::DatabaseTasks.drop_current "test"
ActiveRecord::Tasks::DatabaseTasks.create_current "test"
CreateAllTables.change

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
