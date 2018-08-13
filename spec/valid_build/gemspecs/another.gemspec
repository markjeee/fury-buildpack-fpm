Gem::Specification.new do |s|
  s.name              = 'some_other_gem'
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.version           = ENV["BUILD_VERSION"] || '0.1'
  s.summary           = 'A summary of some_other_gem'
  s.homepage          = 'https://gemfury.com'
  s.email             = 'hello@gemfury.com'
  s.authors           = [ 'An author of some_other_gem' ]
  s.license           = 'MIT'
  s.files             = %w(README.md)

  local_path = File.expand_path('../../', __FILE__)
  Dir.glob(File.join(local_path, '{bin,lib}/**/*')).each do |f|
    s.files << f.gsub('%s/' % local_path, '')
  end

  s.description = <<DESCRIPTION
This may be a long description of some_other_gem.
DESCRIPTION
end
