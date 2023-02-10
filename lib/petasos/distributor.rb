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

    # Process the backfills.

  end

  def find_node(node_name)
    @nodes[node_name]
  end
end
