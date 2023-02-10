# frozen_string_literal: true

require "rake"
require "yaml"

class Petasos::Location
  attr_reader :config

  def initialize(config)
    @config = config
    initialize_all_seen_pool_files
    update_manifest_file
  end

  def run
    # delete exports file if completed file exists
    FileList.new(File.join(Dir.pwd, "exports_#{@config["name"]}*.yaml")).each do |export_file_path|
      completed_export_file_path = "completed-" + export_file_path
      `rm #{export_file_path}` if File.file?(completed_export_file_path)
    end

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
    config["pools"]
  end

  def update_manifest_file
    # a list of pools and their import paths from locations
    pool_imports = Hash.new { |h, k| h[k] = {} }
    pool_exports = Hash.new { |h, k| h[k] = {} }
    pools.each do |pool|
      pool_import_path = pool["import_path"]
      if pool_import_path
        pool_imports[pool["name"]]["import_path"] = File.join(pool["path"], pool_import_path)
        pool_imports[pool["name"]]["backfill"] = pool["backfill"] ? true : false
      end
      if pool["export"]
        pool_exports[pool["name"]]["path"] = pool["path"]
        pool_exports[pool["name"]]["canonical"] = pool["canonical"] ? true : false
      end
    end
    manifest_hash = {
      "name" => config["name"],
      "imports" => pool_imports,
      "exports" => pool_exports,
    }
    write_yaml("manifest_#{config["name"]}.yaml", manifest_hash)
  end

  def included_matchers(pool)
    (pool["included_matchers"] || ["**/*.*"]).map { |fp| File.join(pool["path"], fp) }
  end

  def excluded_matchers(pool)
    (pool["excluded_matchers"] || []).map { |fp| File.join(pool["path"], fp) }
  end

  def current_pool_files(pool)
    FileList.new(included_matchers(pool)).exclude(excluded_matchers(pool))
  end

  def read_seen_pool_files(pool)
    YAML.load_file(File.join(Dir.pwd, "seen_#{config["name"]}_#{pool["name"]}.yaml"))
  end

  def update_seen_pool_files(pool, file_paths)
    yaml_path = File.join(Dir.pwd, "seen_#{config["name"]}_#{pool["name"]}.yaml")
    write_yaml(yaml_path, file_paths)
  end

  def initialize_all_seen_pool_files
    pools.each do |pool|
      yaml_path = "seen_#{config["name"]}_#{pool["name"]}.yaml"
      write_yaml(yaml_path, []) unless File.file?(yaml_path)
    end
  end

  def clear_all_seen_pool_files
    pools.each do |pool|
      yaml_path = File.join(path, "seen_#{pool["name"]}.yaml")
      write_yaml(yaml_path, [])
    end
  end

  def create_file_export_list(pool, file_paths)
    yaml_path = File.join(Dir.pwd, "exports_#{@config["name"]}_#{pool["name"]}_#{Time.now.strftime("%Y-%m-%d-%H:%M:%S")}.yaml")
    write_yaml(yaml_path, file_paths)
  end

  def write_yaml(yaml_path, content)
    File.open(yaml_path, "w") do |out|
      YAML.dump(content, out)
    end
  end
end
