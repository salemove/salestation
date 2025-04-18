# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "salestation"
  spec.version       = "6.0.0"
  spec.authors       = ["Glia TechMovers"]
  spec.email         = ["open-source@glia.com"]

  spec.summary       = %q{}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.14.2"
  spec.add_development_dependency "glia-errors", "~> 0.11.4"
  spec.add_development_dependency "dry-validation", "~> 1.7"
  spec.add_development_dependency "yard-doctest", "~> 0.1.17"

  spec.add_dependency 'deterministic'
  spec.add_dependency 'dry-struct'
  spec.add_dependency 'dry-types'
  spec.add_dependency 'http-accept', '~> 2.1'
  spec.add_dependency 'symbolizer'
end
