# frozen_string_literal: true

require "rake"
require "yaml"

class Petasos::Node
  attr_reader :config

  def initialize(config)
    @config = config
  end

  def grab_imports_and_exports
    `mkdir #{config["name"]}`
    `rsync #{config[:host]}:#{config[:path]}/imports* #{Dir.pwd}/#{config[:name]}/`
    `rsync --ignore-missing-args --ignore-existing #{config[:host]}:#{config[:path]}/exports* #{Dir.pwd}/#{config["name"]}/`
  end
end
