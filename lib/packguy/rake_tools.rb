require 'rbconfig'
require 'fileutils'

class Packguy
  module RakeTools
    BUNDLE_SOURCE_PATH = 'bundle'
    VENDORIZED_FPM_PATH = File.expand_path('../../../bin/support/vendorized_fpm', __FILE__)

    def self.preserve_bundler_config(root_path)
      bundle_config = File.join(root_path, '.bundle/config')

      if File.exists?(bundle_config)
        restore_config = true
        FileUtils.mv(bundle_config, '%s.tmp' % bundle_config)
      else
        restore_config = false
      end

      begin
        ret = yield
      ensure
        if restore_config
          FileUtils.mv('%s.tmp' % bundle_config, bundle_config)
        else
          FileUtils.rm(bundle_config) if File.exists?(bundle_config)
        end
      end

      ret
    end

    def self.bundle_standalone(root_path, bundle_spath = nil)
      if bundle_spath.nil?
        bundle_spath = File.join(root_path, BUNDLE_SOURCE_PATH)
      end

      cmd = '%s %s %s' % [ VENDORIZED_FPM_PATH, root_path, bundle_spath ]
      puts cmd
      Bundler.clean_system(cmd)

      bundle_spath
    end

    def self.bundle_standalone_tarball(root_path, bundle_spath = nil)
      vendor_cache_path = File.join(root_path, 'vendor/buildpack-cache')
      FileUtils.mkpath(vendor_cache_path)

      tb_path = '%s_%s_%s_%s.tar.gz' % [ BUNDLE_SOURCE_PATH,
                                         defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby',
                                         RbConfig::CONFIG['ruby_version'],
                                         RbConfig::CONFIG['arch'] ]
      tb_path = File.join(vendor_cache_path, tb_path)

      bundle_spath = bundle_standalone(root_path, bundle_spath)
      bundle_fname = File.basename(bundle_spath)

      cmd = 'cd %s; tar -czf %s *' % [ bundle_spath, tb_path, bundle_fname ]

      puts cmd
      system(cmd)

      FileUtils.rm_r(bundle_spath)

      tb_path
    end
  end
end
