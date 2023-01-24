# ssh -t xxx.xxx.xxx.xxx "cd /directory_wanted ; bash --login"

@nodes = [
  {
    name: "petasos-node-1",
    host: "justin@localhost",
  },
]

# for every node location
# ssh into it and grab its imports and exports files

# with the import/export files I have, build a hash of pools
# with lists of places files come from and lists of places files go to

# for each exporting node per pool, ssh into it and grab its export files for the pools
# if there are export files I haven't seen before, scp all those files into each of the
# pool import locations (very much like the location process)
