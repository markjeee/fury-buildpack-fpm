require 'bundler'

class Packguy
  class RpmPackage
    def self.build_package(opts = { })
      packager = Packguy.new(opts)

      prefix_path = packager.opts[:rpm_prefix]
      sfiles_map = packager.prepare_files(prefix_path)
      template_values = packager.template_values(prefix_path)
      package_deps = packager.package_dependencies

      fpm_exec_path = Packguy::FpmExec.fpm_exec_path
      rpm_package_file = '%s_%s_%s.rpm' % [ packager.package_name, packager.version, packager.architecture ]
      pkg_file = File.join(packager.pkg_path, rpm_package_file)
      FileUtils.mkpath(File.dirname(pkg_file))

      cmd = '%s --log warn -f -s dir -t rpm --rpm-os linux -a %s -m "%s" -n %s -v %s --description "%s" --url "%s" --license "%s" --vendor "%s" -p %s --after-install %s --template-scripts %s %s %s >/dev/null 2>&1' %
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
              packager.after_install_script,
              package_deps,
              template_values,
              sfiles_map ]

      Bundler.ui.info 'CMD: %s' % cmd
      Bundler.clean_system(cmd)

      Bundler.ui.info 'Created package: %s' % pkg_file

      [ packager, pkg_file ]
    end
  end
end
