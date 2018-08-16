require_relative '../spec_helper'
require 'packguy'

describe 'Packguy fpm exec' do
  context 'build' do
    before do
      BuildpackSpec.packguy_setup
      @packguy = Packguy.new

      prefix_path = Packguy::DebPackage::INSTALL_PREFIX
      @sfiles_map = @packguy.prepare_files(prefix_path)

      @fpm_exec = Packguy::FpmExec.new(@packguy, prefix_path)
    end

    it 'should perform build' do
      package_filename = '%s_%s_%s.deb' % [ @packguy.package_name, @packguy.version, @packguy.architecture ]
      pkg_file_path = @fpm_exec.build(@sfiles_map, package_filename, type: :deb)

      expect(File.exists?(pkg_file_path)).to be_truthy
    end

    it 'should build cmd' do
      package_filename = '%s_%s_%s.deb' % [ @packguy.package_name, @packguy.version, @packguy.architecture ]
      pkg_file = File.join(@packguy.pkg_path, package_filename)

      cmd = @fpm_exec.build_cmd(@sfiles_map, pkg_file, type: :deb)
      expect(cmd).to include('-t deb')
    end

    it 'should specify dependencies' do
      deps = @fpm_exec.package_dependencies
      expect(deps).to include('-d ruby')
    end

    it 'should build a files map' do
      map = @fpm_exec.source_files_map(@sfiles_map)
      expect(map).not_to be_empty
    end
  end
end
