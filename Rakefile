require 'rbconfig'
require 'bundler'
require 'rspec/core/rake_task'
require 'docker_task'

$:.unshift File.expand_path('../lib', __FILE__)
require 'packguy'

RSpec::Core::RakeTask.new('spec')
task :default => :spec

docker_opts = {
  :remote_repo => 'ruby',
  :pull_tag => '1.9.3',
  :image_name => 'ruby193'
}

docker_opts[:run] = lambda do |task, opts|
  opts << '-v %s:/build' % File.expand_path('../', __FILE__)
  opts
end

DockerTask.include_tasks(docker_opts)

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

task :bundle_for_linux do
  ENV['EXEC'] = '/build/exec/build_linux'
  Rake::Task['docker:runi'].invoke
end

task :bundle_for_local => [ :bundle_standalone ]
