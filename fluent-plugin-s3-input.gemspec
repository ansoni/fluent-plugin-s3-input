# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-s3-input"
  spec.version       = "0.0.16"
  spec.authors       = ["Anthony Johnson"]
  spec.email         = ["ansoni@gmail.com"]
  spec.description   = %q{Fluentd plugin to read a file from S3 and emit it}
  spec.summary       = %q{Fluentd plugin to read a file from S3 and emit it}
  spec.homepage      = "https://github.com/ansoni/fluent-plugin-s3-input"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_runtime_dependency     "fluentd"
  spec.add_runtime_dependency     "aws-sdk"
  spec.add_runtime_dependency     "oj"
  spec.add_runtime_dependency     "rubyzip"
end
