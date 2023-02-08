# frozen_string_literal: true

require 'rake'
require 'yaml'

class Petasos::Node
  attr_reader :config

  def initialize(config)
    @config = config
  end

  def grab_imports_and_exports
    `rsync #{config[:host]}:#{config[:path]}/imports* #{File.dirname(__FILE__)}`
    `rsync --ignore-missing-args --ignore-existing #{config[:host]}:#{config[:path]}/exports* #{File.dirname(__FILE__)}`
  end
end