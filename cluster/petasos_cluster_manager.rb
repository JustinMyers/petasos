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
  `scp #{node[:host]}:#{node[:path]}/imports* .`
  `scp #{node[:host]}:#{node[:path]}/exports* .`
end

# with the import/export files I have, build a hash of pools
# with lists of places files come from and lists of places files go to

# for each exporting node per pool, ssh into it and grab its export files for the pools
# if there are export files I haven't seen before, scp all those files into each of the
# pool import locations (very much like the location process)
