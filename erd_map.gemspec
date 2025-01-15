require_relative "lib/erd_map/version"

Gem::Specification.new do |spec|
  spec.name        = "erd_map"
  spec.version     = ErdMap::VERSION
  spec.authors     = [ "makicamel" ]
  spec.email       = [ "unright@gmail.com" ]
  spec.homepage    = "https://github.com/makicamel/erd_map"
  spec.summary     = "An ERD map viewer as a Rails engine."
  spec.description = "ErdMap visualizes key models and associations in Rails applications, helping you understand their architecture by starting with the most important models and allowing zoom-in exploration."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/makicamel/erd_map/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails"
  spec.add_dependency "pycall"
end
