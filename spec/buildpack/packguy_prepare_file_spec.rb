
require_relative '../spec_helper'
require 'packguy'

describe 'Packguy file preparation' do
  context 'prepare files' do
    before do
      BuildpackSpec.packguy_setup
      @packguy = Packguy.new
      @prefix_path = Packguy::DebPackage::INSTALL_PREFIX
    end

    it 'should build source files' do
      files = @packguy.build_source_files(@prefix_path)

      wp = @packguy.package_working_path
      expect(files.keys).to include(File.join(wp, 'some_gem/'))
    end
  end

  context 'gather files' do
    before do
      BuildpackSpec.packguy_setup
      @packguy = Packguy.new
      @prefix_path = Packguy::DebPackage::INSTALL_PREFIX
    end

    it 'should include gem build tool' do
      files = @packguy.gather_files

      expect(files).to include(Packguy.gem_build_extensions_path)
    end
  end
end
