# after_seen hooks
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

# after_export hooks
def after_export_all(file_path)
  puts "#after_export_all: #{File.basename(file_path)}"
end

def after_export_linux_laptop_source(file_path)
  puts "#after_export_location: #{File.basename(file_path)}"
end

def after_export_wow_ah(file_path)
  puts "#after_export_pool: #{File.basename(file_path)}"
end

def after_export_linux_laptop_source_wow_ah(file_path)
  puts "#after_export_location_and_pool: #{File.basename(file_path)}"
end
