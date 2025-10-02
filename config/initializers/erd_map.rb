# frozen_string_literal: true

module ErdMap
  TMP_DIR = Rails.root.join("tmp", "erd_map")
  LOCK_FILE = Rails.root.join("tmp", "erd_map", "task.pid")
  MAP_FILE = Rails.root.join("tmp", "erd_map", "map.html")
end
