# frozen_string_literal: true

ErdMap.py_call_modules = ErdMap::PyCallModules.new

module ErdMap
  TMP_DIR = Rails.root.join("tmp", "erd_map")
  LOCK_FILE = Rails.root.join("tmp", "erd_map", "task.pid")
  MAP_FILE = Rails.root.join("tmp", "erd_map", "map.html")
end
