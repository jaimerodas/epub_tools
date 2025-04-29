require_relative 'lib/epub_tools/version'

Gem::Specification.new do |spec|
  spec.name          = 'epub_tools'
  spec.version       = EpubTools::VERSION
  spec.summary       = 'Tools to extract, split, and compile EPUB books'
  spec.authors       = ['Jaime Rodas']
  spec.email         = ['rodas@hey.com']
  spec.homepage      = 'https://rubygems.org/gems/epub_tools'
  spec.license       = 'MIT'
  spec.files         = `git ls-files`.split("\n")
  spec.require_paths = ['lib']
  spec.executables   = ['epub-tools']
  spec.required_ruby_version = ">= 3.0"

  spec.add_dependency 'nokogiri', '~> 1.18'
  spec.add_dependency 'rubyzip', '~> 2.4'
  spec.add_dependency 'rake', '~> 13.2'

  spec.add_development_dependency 'minitest', '~> 5.25'
  spec.add_development_dependency 'simplecov', '~> 0'
end
