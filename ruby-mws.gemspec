# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ruby-mws/version"

Gem::Specification.new do |s|
  s.name        = "ruby-mws"
  s.version     = MWS::VERSION
  s.authors     = ["Erik Lyngved"]
  s.email       = ["elyngved@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{RubyMWS Gem}
  s.description = %q{Under development!! This gem will serve as a wrapper for Amazon.com's Marketplace Web Service (MWS) API.}

  s.rubyforge_project = "ruby-mws"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
