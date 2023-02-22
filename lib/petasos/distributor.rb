# frozen_string_literal: true

require "rake"
require "yaml"
require "petasos/node"

class Petasos::Distributor
  attr_reader :config

  def initialize(config)
    @config = config
  end

  def run
    @nodes = {}
    @config.each do |node|
      @nodes[node["name"]] = Petasos::Node.new(node)
    end

    @manifests = {}
    @nodes.each_pair do |node_name, node|
      @manifests[node_name] = node.manifests
    end

    # {"petasos-node-a"=>
    #     [{"name"=>"linux-laptop-source",
    #       "imports"=>{},
    #       "exports"=>
    #        {"wow-ah"=>
    #          {"path"=>"/home/justin/play/petasos/test/sandbox/node_a/location_a",
    #           "canonical"=>true}}}],
    #    "petasos-node-b"=>
    #     [{"name"=>"linux-laptop-storage",
    #       "imports"=>
    #        {"wow-ah"=>
    #          {"import_path"=>
    #            "/home/justin/play/petasos/test/sandbox/node_b/location_a/data",
    #           "backfill"=>true}},
    #       "exports"=>{}}]}

    @pools = Hash.new { |h, k|
      h[k] = {
        "import_paths" => [],
        "backfill_import_paths" => [],
        "canonical_exporters" => [],
      }
    }

    puts "petasos: compiling manifests"
    @manifests.each_pair do |node_name, manifest_list|
      manifest_list.each do |manifest|
        manifest["imports"].each_pair do |pool_name, import_hash|
          @pools[pool_name]["import_paths"] << [node_name, import_hash["import_path"]]
          @pools[pool_name]["backfill_import_paths"] << [node_name, manifest["name"], import_hash["import_path"]] if import_hash["backfill"]
        end
        manifest["exports"].each_pair do |pool_name, export_hash|
          @pools[pool_name]["canonical_exporters"] << [node_name, manifest["name"]] if export_hash["canonical"]
        end
      end
    end

    # {"wow-ah"=>
    #     {"import_paths"=>
    #       [["petasos-node-b",
    #         "/home/justin/play/petasos/test/sandbox/node_b/location_a/data"]],
    #      "backfill_import_paths"=>
    #       [["petasos-node-b",
    #         "linux-laptop-storage",
    #         "/home/justin/play/petasos/test/sandbox/node_b/location_a/data"]],
    #      "canonical_exporters"=>[["petasos-node-a", "linux-laptop-source"]]}}

    # Process the exports files and return them as completed.
    puts "petasos: processing exports"
    FileList.new(File.join(Dir.pwd, "**/exports_*")).each do |exports_file_path|
      from_node_name = File.basename(File.dirname(exports_file_path))
      from_node = find_node(from_node_name)
      export_filename = File.basename(exports_file_path, ".*")
      label, location_name, pool_name, datetime = export_filename.split("_")
      export_paths = YAML.load_file(exports_file_path)
      export_paths.each do |export_path|
        @pools[pool_name]["import_paths"].each do |pool_storage|
          to_node = find_node(pool_storage.first)
          `scp #{from_node.host}:#{export_path}* #{to_node.host}:#{pool_storage.last}`
        end
      end
      # mark it as completed
      completed_export_file_path = File.join(Dir.pwd, "completed-#{File.basename(exports_file_path)}")
      `mv #{exports_file_path} #{completed_export_file_path}`
      # and then put it back where it came from
      `scp #{completed_export_file_path} #{from_node.host}:#{from_node.path}`
      `rm #{completed_export_file_path}`
    end

    # {"wow-ah"=>
    #     {"import_paths"=>
    #       [["petasos-node-b",
    #         "/home/justin/play/petasos/test/sandbox/node_b/location_a/data"]],
    #      "backfill_import_paths"=>
    #       [["petasos-node-b",
    #         "linux-laptop-storage",
    #         "/home/justin/play/petasos/test/sandbox/node_b/location_a/data"]],
    #      "canonical_exporters"=>[["petasos-node-a", "linux-laptop-source"]]}}

    # Process the backfills.
    # grab the seen files on the canonical exporters
    @pools.each_pair do |pool_name, manifest_hash|
      manifest_hash["canonical_exporters"].each do |canonical_exporter_details|
        find_node(canonical_exporter_details.first).grab_seen_file_for_location(canonical_exporter_details.last, pool_name)
      end

      # grab the seen files on the backfill importers
      manifest_hash["backfill_import_paths"].each do |backfill_importer_details|
        find_node(backfill_importer_details.first).grab_seen_file_for_location(backfill_importer_details[1], pool_name)
      end

      # for each canonical exporter loop through the backfill lists, identify files that need moving and move them
      manifest_hash["canonical_exporters"].each do |canonical_exporter_details|
        exporter_seen_files = {}
        exporter_file_list = YAML.load_file("seen_#{canonical_exporter_details.last}_#{pool_name}.yaml")
        exporter_file_list.each { |f| exporter_seen_files[File.basename(f)] = f }
        manifest_hash["backfill_import_paths"].each do |backfill_importer_details|
          backfill_importer_files = {}
          backfill_file_list = YAML.load_file("seen_#{backfill_importer_details[1]}_#{pool_name}.yaml")
          backfill_file_list.each { |f| backfill_importer_files[File.basename(f)] = f }

          exporter_seen_files.each_pair do |file_name, file_path|
            unless backfill_importer_files[file_name]
              from_node = find_node(canonical_exporter_details.first)
              to_node = find_node(backfill_importer_details.first)
              `scp #{from_node.host}:#{file_path} #{to_node.host}:#{backfill_importer_details.last}`
            end
          end
        end
      end
      # clear the seen files locally.
      `rm seen_*`
    end
  end

  def find_node(node_name)
    @nodes[node_name]
  end
end
