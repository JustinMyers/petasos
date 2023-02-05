require_relative "./petasos_location"

@node_config = {
  name: "petasos-node-a",
  locations: [
    {
      path: File.join(File.dirname(File.absolute_path(__FILE__)), "location_a"),
    },
  ],
}

# a list of pools and their import paths from locations
@pools = Hash.new { |h, k| h[k] = [] }
@node_config[:locations].each do |location|
  p = PetasosLocation.new(location[:path], @node_config[:name])
  p.pools.each do |pool|
    pool_import_path = p.pool_import_path(pool)
    @pools[pool["name"]] << pool_import_path if pool_import_path
  end
end

File.open(File.join(File.dirname(File.absolute_path(__FILE__)), "imports_#{@node_config[:name]}.yaml"), "w") do |out|
  YAML.dump(@pools, out)
end

@node_config[:locations].each do |location|
  p = PetasosLocation.new(location[:path], @node_config[:name])
  # p.clear_all_seen_pool_files
  p.run
end