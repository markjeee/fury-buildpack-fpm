Gem::Specification.new do |s|
  s.name              = 'custom1_gem'
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.version           = ENV["BUILD_VERSION"] || '0.1'
  s.summary           = 'A summary of custom1_gem'
  s.homepage          = 'https://some_website.com'
  s.email             = 'hello@some_website.com'
  s.authors           = [ 'An author of custom1_gem' ]
  s.license           = 'MIT'
  s.has_rdoc          = false

  s.files             = %w(README.md) +
                        Dir.glob(File.join(File.expand_path('../../', __FILE__), "bin/**/*")) +
                        Dir.glob(File.join(File.expand_path('../../', __FILE__), "lib/**/*"))

  s.description = <<DESCRIPTION
This may be a long description of custom1_gem.
DESCRIPTION
end
