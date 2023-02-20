# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "petasos"
  spec.version = "0.3.1"
  spec.summary = "Petasos identifies new files and distributes them to where they belong"
  spec.description = "Petasos identifies new files and distributes them to where they belong"
  spec.authors = ["Justin Myers"]
  spec.email = ["justin@tenmillionyears.org"]
  spec.homepage = "https://github.com/JustinMyers/petasos"
  spec.license = "MIT"
  spec.files = ["lib/petasos.rb", "lib/petasos/location.rb", "lib/petasos/node.rb", "lib/petasos/distributor.rb", "bin/petasos"]
  spec.executables = "petasos"
  spec.default_executable = "petasos"
  spec.date = "2023-02-14"
  spec.require_paths = ["lib"]
end
