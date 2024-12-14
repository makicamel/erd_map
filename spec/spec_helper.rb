# frozen_string_literal: true

require "active_record/railtie"
require "erd_map"

module ErdMapTestApp
  class Application < Rails::Application
    config.eager_load = false
    config.root = "#{__dir__}/fake_app"
    config.secret_key_base = 'erdmap'
  end
end

ErdMapTestApp::Application.initialize!
ActiveRecord::Tasks::DatabaseTasks.drop_current "test"
ActiveRecord::Tasks::DatabaseTasks.create_current "test"

require_relative "fake_app/fake_app"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
