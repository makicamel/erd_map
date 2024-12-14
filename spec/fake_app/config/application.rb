# require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module ErdMapTestApp
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.secret_key_base = "erdmap"
  end
end

