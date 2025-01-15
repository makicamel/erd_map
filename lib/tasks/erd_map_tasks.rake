# frozen_string_literal: true

desc "Compute erd_map"
  task erd_map: :environment do
  puts "Map computing start."
  ErdMap::MapBuilder.build
  puts "Map computing completed."
end
