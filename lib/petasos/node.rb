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

  def grab_manifest_and_exports
    `rsync #{config["host"]}:#{config["path"]}/manifest* #{config["name"]}/`
    `rsync --ignore-missing-args --ignore-existing #{config["host"]}:#{config["path"]}/exports* #{config["name"]}/`
  end

  def parse_manifests
    FileList.new("#{config["name"]}/manifest_*").each do |manifest_file_path|
      @manifests << YAML.load_file(manifest_file_path)
    end
  end
end
