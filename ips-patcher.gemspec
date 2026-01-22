# frozen_string_literal: true

require_relative "lib/ips/patcher/version"

Gem::Specification.new do |spec|
  spec.name = "ips-patcher"
  spec.version = Ips::Patcher::VERSION
  spec.authors = ["eml"]
  spec.email = ["emanuelbotelho@ymail.com"]

  spec.summary = "Apply IPS patches to video game ROM files."
  spec.description = "Ruby library to parse and apply IPS (.ips) patch files to game ROM images."
  spec.homepage = "https://github.com/meruen/ips-patcher"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/meruen/ips-patcher/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/meruen/ips-patcher/issues"
  spec.metadata["rubygems_mfa_required"] = "false"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # Development dependencies
  spec.add_development_dependency "yard", "~> 0.9"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
