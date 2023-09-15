# frozen_string_literal: true

require "rake"
require "yaml"

class Petasos
  class Error < StandardError; end

  def run(mode = "")
    if mode == "locations"
      lock_and_run("locations") do
        process_locations
      end
    elsif mode == "distribution"
      lock_and_run("distribution") do
        process_distribution
      end
    else # mode is neither distribution or locations
      lock_and_run("locations") do
        process_locations
      end
      lock_and_run("distribution") do
        process_distribution
      end
    end
  end

  def lock_and_run(mode, &block)
    lock_filename = "petasos_is_running_#{mode}"
    if !File.file?(lock_filename)
      puts "did not find lock file #{lock_filename}"
      `touch #{lock_filename}`
      begin
        yield
      rescue StandardError => e
        puts "petasos: error: #{e.message}"
        puts e.backtrace
      end
      `rm #{lock_filename}`
    else
      puts "found lock file #{lock_filename}"
      puts "petasos is already running in #{mode} mode"
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
