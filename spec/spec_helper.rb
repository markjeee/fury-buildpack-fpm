require 'bundler'
require 'fileutils'

ENV['BUNDLE_GEMFILE'] = File.expand_path('../../Gemfile', __FILE__)
Bundler.setup

$:.unshift File.expand_path('../../lib', __FILE__)
require 'packguy'

require 'rspec'

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

# The settings below are suggested to provide a good initial experience
# with RSpec, but feel free to customize to your heart's content.
=begin
  # This allows you to limit a spec run to individual examples or groups
  # you care about by tagging them with `:focus` metadata. When nothing
  # is tagged with `:focus`, all examples get run. RSpec also provides
  # aliases for `it`, `describe`, and `context` that include `:focus`
  # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  config.disable_monkey_patching!

  # This setting enables warnings. It's recommended, but in some cases may
  # be too noisy due to issues in dependencies.
  config.warnings = true

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = "doc"
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed
=end
end

module BuildpackSpec
  TMP_BUILDPACK_SPEC_GEMS = File.expand_path('../../tmp/buildpack_spec/gems', __FILE__)
  TMP_BUILDPACK_SPEC_BUNDLE_WORKING_PATH = File.expand_path('../../tmp/buildpack_spec/bundle', __FILE__)
  COMPILE_PATH = File.expand_path('../../bin/compile', __FILE__)

  VALID_BUILD_PATH = File.expand_path('../valid_build', __FILE__)
  VENDOR_CACHE = File.expand_path('../vendor_cache', __FILE__)

  SPEC_GEMS = {
    'fpm' => 'https://github.com/jordansissel/fpm/archive/master.tar.gz',
    'gemfury' => 'https://github.com/gemfury/gemfury/archive/master.tar.gz',
    'httparty' => 'https://github.com/jnunemaker/httparty/archive/master.tar.gz',
    'diff-lcs' => 'https://github.com/halostatue/diff-lcs/archive/master.tar.gz',
    'puma' => 'https://github.com/puma/puma/archive/master.tar.gz',
    'thin' => 'https://github.com/macournoyer/thin/archive/master.tar.gz'
  }

  def self.compile(build_path, env_vars = { }, opts = { })
    env_vars = env_vars.inject([]) { |a, (k,v)| a << '%s=%s' % [ k, v ]; a }.join(' ')

    cmd = 'env %s %s %s %s' %
          [ env_vars, COMPILE_PATH, build_path, opts[:no_stdout] ? '>/dev/null 2>&1' : '' ]

    system(cmd)
  end

  def self.compile_with_gems(gem_name)
    env_vars = {
      'PACKGUY_BUNDLE_WORKING_PATH' => buildpack_spec_bundle_working_path
    }

    compile(spec_gem_extract_path(gem_name), env_vars, no_stdout: true)
  end

  def self.spec_gem_extract_path(gem_name)
    File.join(buildpack_spec_gems_path, gem_name)
  end

  def self.spec_gem_archive_path(gem_name)
    File.join(buildpack_spec_gems_path, '%s.tar.gz' % gem_name)
  end

  def self.spec_gems
    SPEC_GEMS
  end

  def self.buildpack_spec_gems_path
    TMP_BUILDPACK_SPEC_GEMS
  end

  def self.buildpack_spec_bundle_working_path
    TMP_BUILDPACK_SPEC_BUNDLE_WORKING_PATH
  end

  def self.prepare_buildpack_spec_gems_path
    FileUtils.mkpath(buildpack_spec_gems_path)
  end

  def self.copy_vendor_cache(working_path)
    target_vc_path = Pathname.new(working_path).join('vendor/cache')
    unless target_vc_path.exist?
      FileUtils.mkpath(target_vc_path)
      FileUtils.cp_r(Dir.glob('%s/*' % VENDOR_CACHE), target_vc_path)
    end

    target_vc_path
  end

  def self.packguy_setup(config = { })
    Packguy.config.merge!({ :path => VALID_BUILD_PATH,
                            :working_path => File.join(VALID_BUILD_PATH, 'tmp_packguy_wp'),
                            :bundler_silent => true,
                            :bundler_local => true
                          }.merge(config))
    Packguy.setup
    copy_vendor_cache(Packguy.config[:working_path])

    Packguy
  end
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }
