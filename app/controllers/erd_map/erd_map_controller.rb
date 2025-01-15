# frozen_string_literal: true

module ErdMap
  class ErdMapController < ApplicationController
    FILE_PATH = Rails.root.join("tmp", "erd_map", "map.html")

    def index
      if File.exist?(FILE_PATH)
        render html: File.read(FILE_PATH).html_safe
      else
        _stdout, stderr, status = Open3.capture3("rails runner 'ErdMap::MapBuilder.build'")
        if status.success?
          render html: File.read(FILE_PATH).html_safe
        else
          render plain: "Error: #{stderr}", status: :unprocessable_entity
        end
      end
    end

    def update
      _stdout, stderr, status = Open3.capture3("rails runner 'ErdMap::MapBuilder.build'")
      if status.success?
        head :ok
      else
        render json: { message: "Error: \n#{stderr}" }, status: :unprocessable_entity
      end
    end
  end
end
