def after_seen_all(file_path)
  puts "#after_seen_all: #{File.basename(file_path)}"
end

def after_seen_linux_laptop_source(file_path)
  puts "#after_seen_location: #{File.basename(file_path)}"
end

def after_seen_wow_ah(file_path)
  puts "#after_seen_pool: #{File.basename(file_path)}"
end

def after_seen_linux_laptop_source_wow_ah(file_path)
  puts "#after_seen_location_and_pool: #{File.basename(file_path)}"
end
