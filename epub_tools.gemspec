require_relative 'lib/epub_tools/version'

Gem::Specification.new do |spec|
  spec.name          = 'epub_tools'
  spec.version       = EpubTools::VERSION
  spec.summary       = 'Tools to extract, split, and compile EPUB books'
  spec.authors       = ['Jaime Rodas']
  spec.email         = ['rodas@hey.com']
  spec.homepage      = 'https://github.com/jaimerodas/epub_tools'
  spec.license       = 'MIT'
  spec.files         = `git ls-files`.split("\n")
  spec.require_paths = ['lib']
  spec.executables   = ['epub-tools']
  spec.required_ruby_version = '>= 3.2'
  spec.metadata = {
    'source_code_uri' => 'https://github.com/jaimerodas/epub_tools/tree/main',
    'homepage_uri' => 'https://github.com/jaimerodas/epub_tools',
    'rubygems_mfa_required' => 'true'
  }

  spec.add_dependency 'nokogiri', '~> 1.18'
  spec.add_dependency 'rake', '~> 13.2'
  spec.add_dependency 'rubyzip', '~> 2.4'
end
