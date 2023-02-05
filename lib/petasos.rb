# frozen_string_literal: true

require_relative "petasos/version"

module Petasos
  class Error < StandardError; end

  def run
    process_location_files
    process_distribution_files
  end

  def process_locations
    # look for petasos_location_*.yaml files
    # and pass each one to a petasos location manager
  end

  def process_distribution
    # look for petasos_distribution_*.yaml files
    # and pass each one to a petasos distribution manager
  end
end
