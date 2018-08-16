require 'bundler'

class Packguy
  class FpmExec
    def self.fpm_exec_path
      ENV['FPM_EXEC_PATH'] || Packguy.config[:fpm_exec_path] || 'fpm'
    end

    def initialize(packager, prefix_path)
      @packager = packager
      @prefix_path = prefix_path
    end

    def build(sfiles_map, package_file, opts = { })
      pkg_file = File.join(@packager.pkg_path, package_file)
      FileUtils.mkpath(File.dirname(pkg_file))

      cmd = build_cmd(sfiles_map, pkg_file, opts)

      Bundler.ui.info 'CMD: %s' % cmd
      Bundler.clean_system('%s >/dev/null 2>&1' % cmd)

      pkg_file
    end

    def build_cmd(sfiles_map, pkg_file, opts = { })
      cmd = '%s --log warn -f -s dir' % self.class.fpm_exec_path

      case opts[:type]
      when :rpm
        cmd << ' -t rpm --rpm-os linux'
      when :deb
        cmd << ' -t deb'
      else
        raise 'Unsupported type: %s' % opts[:type]
      end

      cmd << ' -a %s -m "%s" -n %s -v %s --description "%s" --url "%s" --license "%s" --vendor "%s"' %
             [ @packager.architecture,
               @packager.maintainer,
               @packager.package_name,
               @packager.version,
               @packager.description,
               @packager.homepage,
               @packager.license,
               @packager.author ]

      cmd << ' -p %s --after-install %s --template-scripts %s %s %s' %
             [ pkg_file,
               after_install_script,
               package_dependencies,
               template_values,
               source_files_map(sfiles_map) ]

      cmd
    end

    def source_files_map(files)
      files.inject([ ]) do |a, (k,v)|
        a << '%s=%s' % [ k, v ]; a
      end.join(' ')
    end

    def template_values
      values = { 'pg_PACKAGE_PATH' => File.join(@prefix_path, @packager.package_name) }

      values.collect do |k, v|
        '--template-value %s="%s"' % [ k, v ]
      end.join(' ')
    end

    def package_dependencies
      @packager.opts[:dependencies].collect do |k, v|
        if v.nil?
          '-d %s' % k
        else
          '-d "%s%s"' % [ k, v ]
        end
      end.join(' ')
    end

    def after_install_script
      File.expand_path('../../../bin/support/after_install_script', __FILE__)
    end
  end
end
