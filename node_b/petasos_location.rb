require "yaml"
require "rake"

class PetasosLocation
  attr_reader :path, :config, :node_name

  IGNORED_FILES = ["location_config.yaml", "*_seen_files.yaml", "export*.yaml"]

  def initialize(path, node_name)
    @path = path
    @node_name = node_name
    @config = YAML.load_file(File.join(path, "location_config.yaml"))
    initialize_all_seen_pool_files
  end

  def run
    pools.each do |pool|
      # get all filenames in this location that belong to this pool
      current_files = current_pool_files(pool)

      # get all filenames from the list of seen files
      seen_pool_files = read_seen_pool_files(pool)

      # identify which are new
      new_files = current_files - seen_pool_files

      # put a list of the new files where the cluster manager can find it
      # if we are an exporter
      if pool["export"]
        create_file_export_list(pool, new_files.to_a) if new_files.length > 0
      end

      # this is where the "after_seen" hooks would run

      # update list of seen files
      update_seen_pool_files(pool, seen_pool_files + new_files)
    end
  end

  def pools
    @config["pools"]
  end

  def pool_import_path(pool)
    import_path = pools.detect { |p| p["name"] == pool["name"] }&.[]("import_path")
    if import_path
      File.join(path, import_path)
    else
      nil
    end
  end

  def included_matchers(pool)
    (pool["included_matchers"] || ["**/*.*"]).map { |fp| File.join(path, fp) }
  end

  def excluded_matchers(pool)
    (IGNORED_FILES + (pool["excluded_matchers"] || [])).map { |fp| File.join(path, fp) }
  end

  def current_pool_files(pool)
    FileList.new(included_matchers(pool)).exclude(excluded_matchers(pool))
  end

  def read_seen_pool_files(pool)
    seen_files = YAML.load_file(File.join(path, "#{pool["name"]}_seen_files.yaml"))
  end

  def update_seen_pool_files(pool, file_paths)
    File.open(File.join(path, "#{pool["name"]}_seen_files.yaml"), "w") do |out|
      YAML.dump(file_paths, out)
    end
  end

  def initialize_all_seen_pool_files
    pools.each do |pool|
      unless File.file?(File.join(path, "#{pool["name"]}_seen_files.yaml"))
        File.open(File.join(path, "#{pool["name"]}_seen_files.yaml"), "w") do |out|
          YAML.dump([], out)
        end
      end
    end
  end

  def clear_all_seen_pool_files
    pools.each do |pool|
      File.open(File.join(path, "#{pool["name"]}_seen_files.yaml"), "w") do |out|
        YAML.dump([], out)
      end
    end
  end

  def create_file_export_list(pool, file_paths)
    File.open(File.join(File.dirname(__FILE__), "exports_#{node_name}_#{@config["name"]}_#{pool["name"]}_#{Time.now.strftime("%Y-%m-%d-%H:%M:%S")}.yaml"), "w") do |out|
      YAML.dump(file_paths, out)
    end
  end
end
