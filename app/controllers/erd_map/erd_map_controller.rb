# frozen_string_literal: true

module ErdMap
  class ErdMapController < ApplicationController
    skip_forgery_protection

    def index
      if File.exist?(ErdMap::MAP_FILE)
        render html: File.read(ErdMap::MAP_FILE).html_safe
      else
        pid = spawn("rails erd_map")
        Process.detach(pid)
      end
    end

    def update
      File.delete(ErdMap::MAP_FILE) if File.exist?(ErdMap::MAP_FILE)
      pid = spawn("rails erd_map")
      Process.detach(pid)
      redirect_to erd_map.root_path, status: :see_other
    end
  end
end
