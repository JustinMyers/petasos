# frozen_string_literal: true

require "rake"
require "yaml"

class Petasos
  class Error < StandardError; end

  def run(mode = "")
    process_locations
    unless mode == "locations"
      process_distribution if File.file?(File.join(Dir.pwd, "petasos_distribution-config.yaml"))
    end
  end

  def process_locations
    puts "petasos: processing locations"
    # look for petasos_location-*.yaml files
    # and pass each one to a petasos location manager
    FileList.new("petasos_location-*.yaml").each do |location_file|
      YAML.load_file(location_file).each do |location|
        Petasos::Location.new(location).run
      end
    end
  end

  def process_distribution
    puts "petasos: processing distribution"
    # look for petasos_distribution-*.yaml files
    # and pass each one to a petasos distribution
    FileList.new("petasos_distribution-*.yaml").each do |distribution_file|
      node_config = YAML.load_file(distribution_file)
      Petasos::Distributor.new(node_config).run
    end
  end
end

require "petasos/location"
require "petasos/node"
require "petasos/distributor"
