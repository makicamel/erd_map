# frozen_string_literal: true

module ErdMap
  class ErdMapController < ApplicationController
    FILE_PATH = Rails.root.join("tmp", "erd_map", "map.html")

    skip_forgery_protection

    def index
      if File.exist?(FILE_PATH)
        render html: File.read(FILE_PATH).html_safe
      else
        pid = spawn("rails erd_map")
        Process.detach(pid)
      end
    end

    def update
      File.delete(FILE_PATH) if File.exist?(FILE_PATH)
      pid = spawn("rails erd_map")
      Process.detach(pid)
      redirect_to erd_map.root_path, status: :see_other
    end
  end
end
