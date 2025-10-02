# frozen_string_literal: true

desc "Compute erd_map"
task erd_map: :environment do
  tmp_dir = Rails.root.join("tmp", "erd_map")
  FileUtils.makedirs(tmp_dir) unless Dir.exist?(tmp_dir)
  lock_path = Rails.root.join("tmp", "erd_map", "task.pid")

  if File.exist?(lock_path)
    pid = File.read(lock_path).to_i
    alive_process = pid > 0 && (Process.kill(0, pid) rescue false)
    if alive_process
      puts "ErdMap is already computing (pid: #{pid}, file: #{lock_path})."
      exit 0
    end
  end

  File.open(lock_path, File::WRONLY|File::CREAT|File::TRUNC, 0644) do |f|
    f.write(Process.pid)
    f.flush

    puts "Map computing start."
    ErdMap::MapBuilder.build
    puts "Map computing completed."
  end
  File.delete(lock_path)
end
