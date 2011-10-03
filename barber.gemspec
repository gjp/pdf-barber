# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "barber/version"

Gem::Specification.new do |s|
  s.name        = "barber"
  s.version     = Barber::VERSION
  s.authors     = ["Gregory Parkhurst"]
  s.email       = ["six.impossible@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{PDF Barber: Give those muttonchop margins a shave}
  s.description = %q{Barber rewrites the CropBox of books in PDF format to better suit the needs of e-readers. See the README for details.}

  s.rubyforge_project = "barber"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
