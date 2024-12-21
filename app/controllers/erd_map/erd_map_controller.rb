# frozen_string_literal: true

module ErdMap
  class ErdMapController < ApplicationController
    def index
      stdout, stderr, status = Open3.capture3("rails runner 'ErdMap::MapBuilder.build'")
      if status.success?
        render html: File.read(stdout.chomp).html_safe
      else
        render plain: "Error: #{stderr}", status: :unprocessable_entity
      end
    end
  end
end
