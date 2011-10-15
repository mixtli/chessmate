# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "chess/version"

Gem::Specification.new do |s|
  s.name        = "chessmate"
  s.version     = Chess::VERSION
  s.authors     = ["mixtli"]
  s.email       = ["ronmcclain75@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{classes for working with chess}
  s.description = %q{classes for working with chess}
 
  s.rubyforge_project = "chessmate"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec", "2.5.0"
  #s.add_development_dependency "wrong"
  s.add_runtime_dependency "polyglot"
  s.add_runtime_dependency "treetop"
  s.add_runtime_dependency "eventmachine"
end
