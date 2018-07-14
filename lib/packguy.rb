require 'fileutils'
require 'bundler'

class Packguy
  autoload :RakeTools, File.expand_path('../packguy/rake_tools', __FILE__)
  autoload :RakeTask, File.expand_path('../packguy/rake_task', __FILE__)

  BUNDLE_TARGET_PATH = 'bundle'
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
    :working_path => nil
  }

  DEFAULT_PACKAGES = [ :deb, :rpm ]
  DEFAULT_LOCAL_BIN_PATH = '/usr/local/bin'

  PACKAGE_METHOD_MAP = {
    :deb => :build_deb,
    :rpm => :build_rpm
  }

  def self.setup
    load_packfile
    setup_defaults
  end

  def self.setup_defaults
    if ENV.include?('PACKGUY_PACKAGES') && !ENV['PACKGUY_PACKAGES'].empty?
      config[:packages] = ENV['PACKGUY_PACKAGES'].split(',').collect { |p| p.to_sym }
    elsif config[:packages].nil?
      config[:packages] = DEFAULT_PACKAGES
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
    packager = new(opts)

    prefix_path = config[:deb_prefix]
    sfiles_map = packager.prepare_files(prefix_path)

    deb_package_file = '%s_%s_%s.deb' % [ packager.package_name, packager.version, packager.architecture ]
    pkg_file = File.join(packager.pkg_path, deb_package_file)
    FileUtils.mkpath(File.dirname(pkg_file))

    cmd = '%s --log warn -f -s dir -t deb -a %s -m "%s" -n %s -v %s --description "%s" --url "%s" --license "%s" --vendor "%s" -p %s -d ruby %s' %
          [ fpm_exec_path,
            packager.architecture,
            packager.maintainer,
            packager.package_name,
            packager.version,
            packager.description,
            packager.homepage,
            packager.license,
            packager.author,
            pkg_file,
            sfiles_map ]

    puts 'CMD: %s' % cmd
    system(cmd)

    [ packager, pkg_file ]
  end

  def self.build_rpm(opts = { })
    packager = new(opts)

    prefix_path = config[:rpm_prefix]
    sfiles_map = packager.prepare_files(prefix_path)

    rpm_package_file = '%s_%s_%s.rpm' % [ packager.package_name, packager.version, packager.architecture ]
    pkg_file = File.join(packager.pkg_path, rpm_package_file)
    FileUtils.mkpath(File.dirname(pkg_file))

    cmd = '%s --log warn -f -s dir -t rpm --rpm-os linux -a %s -m "%s" -n %s -v %s --description "%s" --url "%s" --license "%s" --vendor "%s" -p %s -d ruby %s' %
          [ fpm_exec_path,
            packager.architecture,
            packager.maintainer,
            packager.package_name,
            packager.version,
            packager.description,
            packager.homepage,
            packager.license,
            packager.author,
            pkg_file,
            sfiles_map ]

    puts 'CMD: %s' % cmd
    system(cmd)

    [ packager, pkg_file ]
  end

  def self.fpm_exec_path
    ENV['FPM_EXEC_PATH'] || 'fpm'
  end

  def initialize(opts = { })
    @opts = self.class.config.merge(opts)

    if @opts[:gemfile].nil?
      @gemfile = Bundler::SharedHelpers.default_gemfile
    else
      @gemfile = Pathname.new(@opts[:gemfile])
    end

    if @opts[:gemspec].nil?
      @gemspec_file = find_default_gemspec_file
    else
      @gemspec_file = @opts[:gemspec]
    end
  end

  def find_default_gemspec_file
    files = [ ]
    try_paths = [ ]

    try_paths << @gemfile.untaint.expand_path.parent.to_s
    try_paths << (@opts[:path] || Dir.pwd)

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
      if ENV['BUNDLE_GEMFILE'].nil?
        ENV['BUNDLE_GEMFILE'] = @gemfile.to_s
      end

      if File.exists?(bundle_working_path)
        FileUtils.rm_r(bundle_working_path)
      end

      install_opts = { }
      install_opts[:without] = [ :development, :test ]
      install_opts[:path] = bundle_working_path
      install_opts[:redownload] = true
      install_opts[:retry] = 3
      install_opts[:jobs] = 3

      Bundler.ui = Bundler::UI::Shell.new
      Bundler.ui.info 'Bundling with: %s' % File.expand_path(ENV['BUNDLE_GEMFILE'])

      Bundler.settings.temporary(install_opts)

      @bundle_def = ::Bundler.definition
      @bundle_def.validate_runtime!
      Bundler::Installer.install(Bundler.root, @bundle_def, install_opts)

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

  def root_path
    File.expand_path('./')
  end

  def pkg_path
    File.join(root_path, 'pkg')
  end

  def bundle_working_path
    File.join(root_path, 'tmp/bundle_wp')
  end

  def working_path
    if @opts[:working_path].nil?
      File.join(root_path, 'tmp/packguy_wp')
    else
      @opts[:working_path]
    end
  end

  def package_name
    if @opts[:package_name].nil?
      gemspec.name
    else
      @opts[:package_name]
    end
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
    specs = bundler_definition.specs_for([ :default ])
    gem_paths = specs.collect do |spec|
      if spec.name != 'bundler' && (gemspec.nil? || spec.name != gemspec.name)
        paths = [ spec.full_gem_path ]
        paths.concat(spec.full_require_paths.collect { |path| path.include?(paths[0]) ? path.gsub(paths[0], '') : nil })
        paths
      else
        nil
      end
    end.compact

    bgems = gem_paths.inject({ }) do |h, a|
      h[File.basename(a.first)] = a; h
    end

    bgems
  end

  def gather_files_for_package
    files = { }

    unless gemspec.nil?
      gemspec.files.each do |fname|
        next if File.directory?(fname)

        if fname =~ /^lib\/(.+)$/
          files[fname] = fname
        elsif fname =~ /^bin\/(.+)$/
          files[fname] = fname
        else
          # ignore, other files
        end
      end
    end

    bgems = bundle_gems
    bgems.each do |gem_name, src_paths|
      src_path = src_paths.first
      files[src_path] = File.join(BUNDLE_TARGET_PATH, gem_name)
    end

    files
  end

  def create_bundle_setup_rb
    bundle_setup_file = File.join(BUNDLE_TARGET_PATH, BUNDLE_BUNDLER_SETUP_FILE)
    bundle_setup_path = File.join(working_path, package_name, bundle_setup_file)

    FileUtils.mkpath(File.dirname(bundle_setup_path))

    bgems = bundle_gems
    File.open(bundle_setup_path, 'w') do |f|
      bgems.each do |gem_name, src_paths|
        if src_paths.count > 1
          rpaths = src_paths[1..-1]
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
    prefix_path = File.join(working_path, package_name)

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

    src_bin_path = File.join(working_path, 'bin', binstub_fname)
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

    source_path = File.join(working_path, package_name, '/')
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

  def source_files_map(files)
    files.inject([ ]) do |a, (k,v)|
      a << '%s=%s' % [ k, v ]; a
    end.join(' ')
  end
end
