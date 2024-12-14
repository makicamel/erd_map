# frozen_string_literal: true

# Models from doorkeeper
# https://github.com/doorkeeper-gem/doorkeeper
class OauthAccessGrant < ApplicationRecord
  belongs_to :application, class_name: Doorkeeper.config.application_class.to_s,
                           optional: true,
                           inverse_of: :access_grants
end
