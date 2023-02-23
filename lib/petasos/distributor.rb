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
          @pools[pool_name]["import_paths"] << [node_name, manifest["name"], import_hash["import_path"]]
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
    #         "linux-laptop-storage",
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
      @pools[pool_name]["import_paths"].each do |pool_storage|
        to_node = find_node(pool_storage.first)
        destination_seen_file_hash = get_seen_file_hash(pool_storage.first, pool_storage[1], pool_name)
        export_paths.each do |export_path|
          unless destination_seen_file_hash[File.basename(export_path)]
            puts "exporting #{File.basename(export_path)} from #{from_node.name} to #{to_node.name}"
            `scp #{from_node.host}:#{export_path}* #{to_node.host}:#{pool_storage.last}`
          end
        end
        puts "Running `petasos locations` on #{to_node.name} after export from #{from_node.name}"
        `ssh #{to_node.host} \"cd #{to_node.path} && petasos locations\"`
      end
      # mark it as completed
      completed_export_file_path = File.join(Dir.pwd, "completed-#{File.basename(exports_file_path)}")
      `mv #{exports_file_path} #{completed_export_file_path}`
      # and then put it back where it came from
      `scp #{completed_export_file_path} #{from_node.host}:#{from_node.path}`
      `rm #{completed_export_file_path}`
      puts "Running `petasos locations` on #{from_node.name} after completing its exports"
      `ssh #{from_node.host} \"cd #{from_node.path} && petasos locations\"`
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
    @pools.each_pair do |pool_name, manifest_hash|
      `mkdir -p petasos_distributor_workspace`
      # for each canonical exporter loop through the backfill lists, identify files that need moving and move them
      manifest_hash["canonical_exporters"].each do |canonical_exporter_details|
        exporter_seen_files = get_seen_file_hash(canonical_exporter_details.first, canonical_exporter_details.last, pool_name)
        manifest_hash["backfill_import_paths"].each do |backfill_importer_details|
          backfill_importer_files = get_seen_file_hash(backfill_importer_details.first, backfill_importer_details[1], pool_name)

          from_node = find_node(canonical_exporter_details.first)
          to_node = find_node(backfill_importer_details.first)

          exporter_seen_files.each_pair do |file_name, file_path|
            unless backfill_importer_files[file_name]
              puts "Backfilling #{file_name} to #{to_node.name} from #{from_node.name}"
              `scp #{from_node.host}:#{file_path} #{to_node.host}:#{backfill_importer_details.last}`
            end
          end

          puts "Running `petasos locations` on #{to_node.name} after backfill from #{from_node.name}"
          `ssh #{to_node.host} \"cd #{to_node.path} && petasos locations\"`
        end
      end
    end
    # clear the seen files locally.
    `rm petasos_distributor_workspace/*`
  end

  def get_seen_file_hash(node_name, location_name, pool_name)
    find_node(node_name).grab_seen_file_for_location(location_name, pool_name)
    seen_file_hash = {}
    # some locations/pools do not generate a seen file.
    if File.file?("petasos_distributor_workspace/seen_#{location_name}_#{pool_name}.yaml")
      seen_file_list = YAML.load_file("petasos_distributor_workspace/seen_#{location_name}_#{pool_name}.yaml")
    else
      seen_file_list = []
    end
    seen_file_list.each { |f| seen_file_hash[File.basename(f)] = f }
    seen_file_hash
  end

  def find_node(node_name)
    @nodes[node_name]
  end
end
