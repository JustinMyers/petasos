# frozen_string_literal: true

require "rake"
require "yaml"

class Petasos::Node
  attr_reader :config, :manifests

  def initialize(config)
    @config = config
    @manifests = []
    `mkdir -p #{config["name"]}`
    grab_manifest_and_exports
    parse_manifests
  end

  def host
    @config["host"]
  end

  def path
    @config["path"]
  end

  def grab_manifest_and_exports
    `rsync #{config["host"]}:#{config["path"]}/manifest* #{config["name"]}/`
    rysnc_path = "--rsync-path=#{config["rsync_path"]}"
    `rsync --ignore-missing-args #{rsync_path} --ignore-existing #{config["host"]}:#{config["path"]}/exports* #{config["name"]}/`
  end

  def grab_seen_file_for_location(location_name, pool_name)
    `scp #{config["host"]}:#{config["path"]}/seen_#{location_name}_#{pool_name}.yaml .`
  end

  def parse_manifests
    FileList.new("#{config["name"]}/manifest_*").each do |manifest_file_path|
      @manifests << YAML.load_file(manifest_file_path)
    end
  end
end
