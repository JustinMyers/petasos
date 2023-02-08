# frozen_string_literal: true

require "rake"
require "yaml"

class Petasos
  class Error < StandardError; end

  def run
    process_locations
    # process_distribution
  end

  def process_locations
    # look for petasos_location-*.yaml files
    # and pass each one to a petasos location manager
    FileList.new("petasos_location-*.yaml").each do |location_file|
      YAML.load_file(location_file).each do |location|
        Petasos::Location.new(location).run
      end
    end
  end

  def process_distribution
    # look for petasos_distribution-*.yaml files
    # and pass each one to a petasos distribution

    # with the import/export files I have, build a hash of pools
    # with lists of places files come from and lists of places files go to
    @pools = Hash.new { |h, k| h[k] = [] }
    FileList.new(File.join(File.dirname(File.absolute_path(__FILE__)), "imports_*")).each do |import_file_path|
      pool_import_locations = YAML.load_file(import_file_path)
      node_name = import_file_path.split("_")[1].split(".")[0]
      node = find_node(node_name)
      pool_import_locations.each_pair do |k, v|
        v.map! { |import_path| "#{node[:host]}:#{import_path}" }
        @pools[k] += v
      end
    end

    # for each exporting node per pool, ssh into it and grab its export files for the pools
    # if there are export files I haven't seen before, scp all those files into each of the
    # pool import locations (very much like the location process)
    FileList.new(File.join(File.dirname(File.absolute_path(__FILE__)), "exports_*")).each do |exports_file_path|
      export_filename = File.basename(exports_file_path, ".*")
      label, node_name, location_name, pool_name, datetime = exports_file_path.split("_")
      node = find_node(node_name)
      export_paths = YAML.load_file(exports_file_path)
      export_paths.each do |export_path|
        @pools[pool_name].each do |pool_storage|
          `scp #{node[:host]}:#{export_path}* #{pool_storage}`
        end
      end
      # mark it as completed
      completed_export_file_path = "#{File.dirname(exports_file_path)}/completed-#{File.basename(exports_file_path)}"
      `mv #{exports_file_path} #{completed_export_file_path}`
      # and then put it back where it came from
      `scp #{completed_export_file_path} #{node[:host]}:#{node[:path]}`
      `rm #{completed_export_file_path}`
    end
  end

  def find_node(node_name)
    @nodes.detect { |n| n[:name] == node_name }
  end
end

require "petasos/location"
