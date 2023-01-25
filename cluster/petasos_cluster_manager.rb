require "yaml"
require "rake"

# ssh -t xxx.xxx.xxx.xxx "cd /directory_wanted ; bash --login"

@nodes = [
  {
    name: "petasos-node-a",
    host: "justin@localhost",
    path: "/home/justin/play/petasos/node_a",
  },
  {
    name: "petasos-node-b",
    host: "justin@localhost",
    path: "/home/justin/play/petasos/node_b",
  },
]

# for every node location
# ssh into it and grab its imports and exports files
@nodes.each do |node|
  `rsync #{node[:host]}:#{node[:path]}/imports* #{File.dirname(__FILE__)}`
  `rsync --ignore-missing-args --ignore-existing #{node[:host]}:#{node[:path]}/exports* #{File.dirname(__FILE__)}`
end

# with the import/export files I have, build a hash of pools
# with lists of places files come from and lists of places files go to
@pools = Hash.new { |h, k| h[k] = [] }
FileList.new("imports_*").each do |import_file_path|
  pool_import_locations = YAML.load_file(import_file_path)
  pool_import_locations.each_pair do |k, v|
    @pools[k] += v
  end
end

# for each exporting node per pool, ssh into it and grab its export files for the pools
# if there are export files I haven't seen before, scp all those files into each of the
# pool import locations (very much like the location process)
FileList.new("exports_*").each do |import_file_path|
  export_paths = YAML.load_file(import_file_path)
  import_filename = import_file_path.split(".")[0]
  label, node_name, location_name, pool_name, datetime = import_filename.split("_")
  node = @nodes.detect { |n| n[:name] == node_name }
  export_paths.each do |export_path|
    @pools[pool_name].each do |pool_storage|
      storage
      `rsync --ignore-missing-args --ignore-existing #{node[:host]}:#{export_path}* #{File.dirname(__FILE__)}`
    end
  end
end
