source 'https://rubygems.org'

gem 'rake'
gem 'fpm'

source 'https://repo.nlevel.io/ruby/' do
  gem 'packguy'
end

group :development, :test do
  gem 'rspec'

  #gem 'docker_task', :path => File.expand_path('~/work/docker_task')
  source 'https://repo.nlevel.io/ruby/' do
    gem 'docker_task', '~> 0.1.4'
  end
end
