# frozen_string_literal: true

desc "Compute erd_map"
task erd_map: :environment do
  FileUtils.makedirs(ErdMap::TMP_DIR) unless Dir.exist?(ErdMap::TMP_DIR)
  timeout = 5 * 60

  if File.exist?(ErdMap::LOCK_FILE)
    pid = File.read(ErdMap::LOCK_FILE).to_i

    if Time.now - File.mtime(ErdMap::LOCK_FILE) > timeout
      puts "Lock expired. Kill process and remove lock file (pid: #{pid}, file: #{ErdMap::LOCK_FILE})."
      Process.kill("KILL", pid) rescue nil
      File.delete(ErdMap::LOCK_FILE)
    else
      puts "ErdMap is already computing (pid: #{pid}, file: #{ErdMap::LOCK_FILE})."
      exit 0
    end
  end

  File.open(ErdMap::LOCK_FILE, File::WRONLY|File::CREAT|File::TRUNC, 0644) do |f|
    f.write(Process.pid)
    f.flush

    puts "Map computing start."
    ErdMap::MapBuilder.build
    puts "Map computing completed."
  end
  File.delete(ErdMap::LOCK_FILE)
end
