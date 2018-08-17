require 'rbconfig'
require 'bundler'

Bundler.setup
$:.unshift File.expand_path('../lib', __FILE__)

require 'rspec/core/rake_task'
require 'docker_task'
require 'packguy'

RSpec::Core::RakeTask.new('spec')
task :default => :spec

docker_run = lambda do |task, opts|
  opts << '-v %s:/build' % File.expand_path('../', __FILE__)
  opts
end

DockerTask.create({ :remote_repo => 'nlevel/rubydev25',
                    :pull_tag => 'latest',
                    :image_name => 'fury-buildpack-fpm-ruby251',
                    :run => docker_run })

DockerTask.create({ :remote_repo => 'nlevel/rubydev19',
                    :pull_tag => 'latest',
                    :image_name => 'fury-buildpack-fpm-ruby193',
                    :run => docker_run })

DockerTask.include_tasks(:use => 'fury-buildpack-fpm-ruby251')

desc 'Create bundle standalone'
task :bundle_standalone do
  bundle_spath = Packguy::RakeTools.bundle_standalone(
    File.expand_path('./'), File.expand_path('../bundle', __FILE__))

  puts 'Created bundle standalone path: %s' % bundle_spath
end

desc 'Create bundled tar ball'
task :bundle_standalone_tarball do
  tarball_path = Packguy::RakeTools.bundle_standalone_tarball(
    File.expand_path('./'), File.expand_path('../bundle_tarball', __FILE__))

  puts 'Created bundle cache file: %s' % tarball_path
end

desc 'Create bundle for linux with ruby 1.9.3'
task :bundle_for_linux do
  c = DockerTask.containers['fury-buildpack-fpm-ruby251']
  c.runi(:exec => '/build/exec/build_linux', :su => 'rubydev')
end

task :bundle_for_local => [ :bundle_standalone ]
