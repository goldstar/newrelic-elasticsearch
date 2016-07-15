# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'new_relic/elasticsearch/version'

Gem::Specification.new do |spec|
  spec.name          = "new_relic-elasticsearch"
  spec.version       = NewRelic::Elasticsearch::VERSION
  spec.authors       = ["Stephen Prater"]
  spec.email         = ["me@stephenprater.com"]

  spec.summary       = %q{Provides NewRelic datastore instrumentation for Elasticsearch}
  spec.description   = %q{Not for monitoring Elasticsearch, but for instrumenting it as
                          as a datatore in the databases tab in NewRelic}
  spec.homepage      = "http://github.com/goldstar/new_relic-elasticsearch"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 4.7.5"
  spec.add_development_dependency "webmock"
  spec.add_dependency "newrelic_rpm"
  spec.add_dependency "elasticsearch"
end
