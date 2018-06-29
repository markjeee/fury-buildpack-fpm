require 'bundler'
require 'rspec/core/rake_task'

$:.unshift File.expand_path('../lib', __FILE__)
require 'packguy'

RSpec::Core::RakeTask.new('spec')
task :default => :spec

task :vendorized_fpm do
  Packguy.setup
  Packguy.config[:package_name] = 'fury-buildpack-fpm'

  packager = Packguy.new
  packager.prepare_files(Packguy.config[:deb_prefix])
end
