require 'fileutils'
require 'bundler'

class Packguy
  autoload :RakeTools, File.expand_path('../packguy/rake_tools', __FILE__)
  autoload :RakeTask, File.expand_path('../packguy/rake_task', __FILE__)
  autoload :PatchBundlerNoMetadataDeps, File.expand_path('../packguy/patch_bundler_no_metadata_deps', __FILE__)

  autoload :DebPackage, File.expand_path('../packguy/deb_package', __FILE__)
  autoload :RpmPackage, File.expand_path('../packguy/rpm_package', __FILE__)

  autoload :FpmExec, File.expand_path('../packguy/fpm_exec', __FILE__)

  BUNDLE_TARGET_PATH = 'bundle'
  BUNDLE_EXTENSIONS_PATH = 'extensions'
  BUNDLE_PACKGUY_TOOLS_PATH = 'packguy_tools'
  BUNDLE_BUNDLER_SETUP_FILE = 'bundler/setup.rb'

  PACKGUY_PACKFILE = 'Packfile'

  DEFAULT_CONFIG = {
    :path => nil,
    :gemspec => nil,
    :gemfile => nil,
    :binstub =>  nil,
    :packages => nil,
    :architecture => 'all',

    :rpm_prefix => '/usr/share/ruby/vendor_ruby/',
    :deb_prefix => '/usr/lib/ruby/vendor_ruby/',

    # maybe specified, if wanting to override as set in gemspec file
    :package_name => nil,
    :working_path => nil,

    :dependencies => { },
    :bundle_working_path => nil,

    :fpm_exec_path => nil,
    :bundler_silent => false,
    :bundler_local => false
  }

  DEFAULT_PACKAGES = [ :deb, :rpm ]
  DEFAULT_LOCAL_BIN_PATH = '/usr/local/bin'

  PACKAGE_METHOD_MAP = {
    :deb => :build_deb,
    :rpm => :build_rpm
  }

  def self.load_patch
    PatchBundlerNoMetadataDeps.patch!
  end

  def self.setup
    load_patch
    load_packfile
    setup_defaults
  end

  def self.setup_defaults
    if ENV.include?('PACKGUY_PACKAGES') && !ENV['PACKGUY_PACKAGES'].empty?
      config[:packages] = ENV['PACKGUY_PACKAGES'].split(',').collect { |p| p.to_sym }
    elsif config[:packages].nil?
      config[:packages] = DEFAULT_PACKAGES
    end

    if ENV.include?('PACKGUY_BUNDLE_WORKING_PATH')
      config[:bundle_working_path] = File.expand_path(ENV['PACKGUY_BUNDLE_WORKING_PATH'])
    end

    unless config[:dependencies].include?('ruby')
      config[:dependencies]['ruby'] = nil
    end
  end

  def self.load_packfile
    packfile_path = nil

    if ENV.include?('PACKGUY_PACKFILE')
      packfile_path = File.expand_path(ENV['PACKGUY_PACKFILE'])
    else
      packfile_path = search_up(PACKGUY_PACKFILE)
    end

    unless packfile_path.nil?
      load packfile_path
    end

    packfile_path
  end

  def self.search_up(*names)
    previous = nil
    current  = File.expand_path(config[:path] || Dir.pwd).untaint
    found_path = nil

    until !File.directory?(current) || current == previous || !found_path.nil?
      names.each do |name|
        path = File.join(current, name)
        if File.exists?(path)
          found_path = path
          break
        end
      end

      if found_path.nil?
        previous = current
        current = File.expand_path("..", current)
      end
    end

    found_path
  end

  def self.configure
    yield config
  end

  def self.config
    if defined?(@@global_config)
      @@global_config
    else
      @@global_config = DEFAULT_CONFIG.merge({ })
    end
  end

  def self.build_package(opts = { })
    packages = Packguy.config[:packages]
    packages.each do |pack|
      build_method = PACKAGE_METHOD_MAP[pack]
      unless build_method.nil?
        send(build_method, opts)
      end
    end
  end

  def self.build_deb(opts = { })
    DebPackage.build_package(opts)
  end

  def self.build_rpm(opts = { })
    RpmPackage.build_package(opts)
  end

  def self.gem_build_extensions_path
    File.expand_path('../../bin/support/gem_build_extensions', __FILE__)
  end

  def self.silence_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    ret = yield
    $VERBOSE = original_verbosity
    ret
  end

  attr_reader :opts
  attr_reader :gemfile
  attr_reader :gemspec_file

  def initialize(opts = { })
    @opts = self.class.config.merge(opts)

    unless @opts[:gemfile].nil?
      @gemfile = Pathname.new(@opts[:gemfile])
    else
      @gemfile = nil
    end

    if @opts[:gemspec].nil?
      @gemspec_file = find_default_gemspec_file
    else
      @gemspec_file = @opts[:gemspec]
    end

    if @gemfile.nil?
      @gemfile = autogenerate_clean_gemfile
    end

    self
  end

  def find_default_gemspec_file
    files = [ ]
    try_paths = [ ]

    unless @gemfile.nil?
      try_paths << @gemfile.untaint.expand_path.parent.to_s
    end

    try_paths << root_path

    try_paths.detect do |tpath|
      files.concat(Dir.glob(File.join(tpath, '{,*}.gemspec')))
      files.count > 0
    end

    unless files.empty?
      File.expand_path(files.first)
    else
      nil
    end
  end

  def bundler_definition
    if defined?(@bundle_def)
      @bundle_def
    else
      ENV['BUNDLE_GEMFILE'] = @gemfile.to_s

      install_opts = { }
      install_opts[:with] = [ :default ]
      install_opts[:without] = [ :development, :test, :documentation ]
      install_opts[:path] = bundle_working_path
      install_opts[:retry] = 3
      install_opts[:jobs] = 3

      # in case, we are called multiple times
      Bundler.reset!

      if @opts[:bundler_silent]
        Bundler.ui = Bundler::UI::Silent.new
      else
        Bundler.ui = Bundler::UI::Shell.new
        Bundler.ui.info 'Bundling with: %s' % @gemfile.to_s
      end

      if @opts[:bundler_local]
        install_opts[:local] = true
      end

      self.class.silence_warnings do
        Bundler.settings.temporary(install_opts) do
          @bundle_def = ::Bundler.definition
          @bundle_def.validate_runtime!
        end

        Bundler.settings.temporary({ :no_install => true }.merge(install_opts)) do
          Bundler::Installer.install(Bundler.root, @bundle_def, install_opts)
        end
      end

      rubygems_dir = Bundler.rubygems.gem_dir
      FileUtils.mkpath(File.join(rubygems_dir, 'specifications'))

      @bundle_def.specs.each do |spec|
        next unless spec.source.is_a?(Bundler::Source::Rubygems)

        cached_gem = spec.source.send(:cached_gem, spec)
        installer = Gem::Installer.at(cached_gem, :path => rubygems_dir)
        installer.extract_files
        installer.write_spec
      end

      @bundle_def
    end
  end

  def gemspec
    if defined?(@spec)
      @spec
    elsif !@gemspec_file.nil?
      @spec = Gem::Specification.load(@gemspec_file)
    else
      @spec = nil
    end
  end

  def autogenerate_clean_gemfile
    FileUtils.mkpath(working_path)

    gemfile_path = File.join(working_path, 'Gemfile')
    File.open(gemfile_path, 'w') do |f|
      gemfile_content = <<GEMFILE
source "http://rubygems.org"
gemspec :path => '%s', :name => '%s'
GEMFILE

      gemfile_content = gemfile_content % [ File.dirname(@gemspec_file),
                                            File.basename(@gemspec_file, '.gemspec') ]
      f.write(gemfile_content)
    end

    Pathname.new(gemfile_path)
  end

  def root_path
    if @opts[:path].nil?
      File.expand_path('./')
    else
      @opts[:path]
    end
  end

  def pkg_path
    File.join(root_path, 'pkg')
  end

  def working_path
    if @opts[:working_path].nil?
      File.join(root_path, 'tmp/packguy_wp')
    else
      @opts[:working_path]
    end
  end

  def bundle_working_path
    @opts[:bundle_working_path] || File.join(working_path, 'bundle')
  end

  def package_working_path
    File.join(working_path, 'package')
  end

  def package_name
    if @opts[:package_name].nil?
      gemspec.name
    else
      @opts[:package_name]
    end
  end

  def after_install_script
    File.expand_path('../../bin/support/after_install_script', __FILE__)
  end

  def version
    gemspec.version
  end

  def description
    gemspec.description.strip
  end

  def homepage
    gemspec.homepage
  end

  def author
    gemspec.authors.join(', ')
  end

  def license
    gemspec.license
  end

  def maintainer
    case gemspec.email
    when Array
      gemspec.email.first
    when String
      gemspec.email
    else
      nil
    end
  end

  def architecture
    @opts[:architecture]
  end

  def bundle_gems
    bgems = { }
    specs = bundler_definition.specs_for([ :default ])

    specs.each do |spec|
      if spec.name != 'bundler' && (gemspec.nil? || spec.name != gemspec.name)
        orig_spec = spec
        if spec.is_a?(Bundler::EndpointSpecification)
          rs = spec.instance_variable_get(:@remote_specification)
          if rs
            spec = rs
          elsif spec._local_specification
            spec = spec._local_specification
          end
        end

        bhash = { }

        bhash[:orig_spec] = orig_spec
        bhash[:spec] = spec
        bhash[:gem_path] = spec.full_gem_path

        bhash[:files] = Dir.glob(File.join(spec.full_gem_path, '**/*')).inject([ ]) { |a, f|
          unless File.directory?(f)
            a << f.gsub('%s/' % spec.full_gem_path, '')
          end

          a
        }.uniq

        bhash[:require_paths] = spec.full_require_paths.collect { |path|
          path.include?(bhash[:gem_path]) ?
            path.gsub(bhash[:gem_path], '') : nil
        }.compact

        bgems[spec.name] = bhash
      end
    end

    bgems
  end

  def add_ruby_build_dependencies!
    unless @opts[:dependencies].include?('ruby-dev')
      @opts[:dependencies]['ruby-dev'] = @opts[:dependencies]['ruby']
    end

    unless @opts[:dependencies].include?('ruby-build')
      @opts[:dependencies]['ruby-build'] = @opts[:dependencies]['ruby']
    end

    @opts[:dependencies]
  end

  def gather_files_for_package
    files = { }

    unless gemspec.nil?
      (gemspec.files - gemspec.test_files).each do |fname|
        next if File.directory?(fname)
        fname = fname.gsub('%s/' % gemspec.full_gem_path, '')
        files[fname] = fname
      end
    end

    include_packguy_tools = false

    bgems = bundle_gems
    bgems.each do |gem_name, bhash|
      bhash[:files].each do |file|
        src_full_path = File.join(bhash[:gem_path], file)
        files[src_full_path] = File.join(BUNDLE_TARGET_PATH, gem_name, file)
      end

      unless bhash[:spec].extensions.empty?
        add_ruby_build_dependencies!
        include_packguy_tools = true

        files[bhash[:orig_spec].loaded_from] = File.join(BUNDLE_EXTENSIONS_PATH, '%s.gemspec' % gem_name)
      end
    end

    if include_packguy_tools
      files = gather_packguy_tools_for_package(files)
    end

    files
  end

  def gather_packguy_tools_for_package(files)
    gem_build_extensions_path = self.class.gem_build_extensions_path
    target_tools_path = File.join(BUNDLE_PACKGUY_TOOLS_PATH)

    files[gem_build_extensions_path] = File.join(target_tools_path, File.basename(gem_build_extensions_path))

    files
  end

  def create_bundle_setup_rb
    bundle_setup_file = File.join(BUNDLE_TARGET_PATH, BUNDLE_BUNDLER_SETUP_FILE)
    bundle_setup_path = File.join(package_working_path, package_name, bundle_setup_file)

    FileUtils.mkpath(File.dirname(bundle_setup_path))

    bgems = bundle_gems
    File.open(bundle_setup_path, 'w') do |f|
      f.puts '# Adding require paths to load path (empty if no gems is needed)'
      f.puts ''

      bgems.each do |gem_name, bhash|
        spec = bhash[:spec]
        f.puts '# == Gem: %s, version: %s' % [ spec.name, spec.version ]

        src_paths = bhash[:require_paths]
        if src_paths.count > 0
          rpaths = src_paths.dup
        else
          rpaths = [ '/lib' ]
        end

        rpaths.each do |rpath|
          load_path_line = "$:.unshift File.expand_path('../../%s%s', __FILE__)" % [ gem_name, rpath ]
          f.puts(load_path_line)
        end
      end
    end

    [ bundle_setup_file, bundle_setup_path ]
  end

  def gather_files
    prefix_path = File.join(package_working_path, package_name)

    if File.exists?(prefix_path)
      FileUtils.rm_r(prefix_path)
    end

    FileUtils.mkpath(prefix_path)

    files = gather_files_for_package
    files.each do |fsrc, ftarget|
      if fsrc =~ /^\//
        fsrc_path = fsrc
      else
        fsrc_path = File.join(root_path, fsrc)
      end

      ftarget_path = File.join(prefix_path, ftarget)

      FileUtils.mkpath(File.dirname(ftarget_path))
      FileUtils.cp_r(fsrc_path, ftarget_path)
    end

    fsrc, ftarget = create_bundle_setup_rb
    files[fsrc] = ftarget

    files
  end

  def create_binstub(binstub_fname, prefix_path)
    binstub_code = <<CODE
#!/usr/bin/env ruby

require "%s"
load "%s"
CODE

    src_bin_path = File.join(package_working_path, 'bin', binstub_fname)
    FileUtils.mkpath(File.dirname(src_bin_path))

    bundler_setup_path = File.join(prefix_path, package_name, BUNDLE_TARGET_PATH, BUNDLE_BUNDLER_SETUP_FILE)

    bindir_name = gemspec.nil? ? 'bin' : gemspec.bindir
    actual_bin_path = File.join(prefix_path, package_name, bindir_name, binstub_fname)

    File.open(src_bin_path, 'w') { |f| f.write(binstub_code % [ bundler_setup_path, actual_bin_path ]) }
    FileUtils.chmod(0755, src_bin_path)

    src_bin_path
  end

  def build_source_files(prefix_path)
    files = { }

    source_path = File.join(package_working_path, package_name, '/')
    target_path = File.join(prefix_path, package_name)
    files[source_path] = target_path

    files
  end

  def prepare_files(prefix_path)
    gather_files

    files = build_source_files(prefix_path)

    if @opts[:binstub].nil?
      unless gemspec.nil? || gemspec.executables.nil? || gemspec.executables.empty?
        @opts[:binstub] = { }

        gemspec.executables.each do |exec_fname|
          @opts[:binstub][exec_fname] = File.join(DEFAULT_LOCAL_BIN_PATH, exec_fname)
        end
      end
    end

    @opts[:binstub].each do |binstub_fname, binstub_file|
      src_binstub_file = create_binstub(binstub_fname, prefix_path)
      files[src_binstub_file] = binstub_file
    end unless @opts[:binstub].nil?

    source_files_map(files)
  end

  def package_dependencies
    @opts[:dependencies].collect do |k, v|
      if v.nil?
        '-d %s' % k
      else
        '-d "%s%s"' % [ k, v ]
      end
    end.join(' ')
  end

  def template_values(prefix_path)
    values = { 'pg_PACKAGE_PATH' => File.join(prefix_path, package_name) }

    values.collect do |k, v|
      '--template-value %s="%s"' % [ k, v ]
    end.join(' ')
  end

  def source_files_map(files)
    files.inject([ ]) do |a, (k,v)|
      a << '%s=%s' % [ k, v ]; a
    end.join(' ')
  end
end
