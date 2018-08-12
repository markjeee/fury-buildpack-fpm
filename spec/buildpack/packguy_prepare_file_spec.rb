require 'spec_helper'
require 'packguy'

describe 'Packguy files preparation' do
  context 'prepare files' do
    before do
      BuildpackSpec.packguy_setup
      @packguy = Packguy.new
      @prefix_path = @packguy.opts[:deb_prefix]
    end

    it 'should create files map' do
      source_files_map = @packguy.prepare_files(@prefix_path)

      expect(source_files_map).not_to be_nil
      expect(source_files_map).not_to be_empty
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
      @prefix_path = @packguy.opts[:deb_prefix]
    end

    it 'should gather gem files' do
      files = @packguy.gather_files

      expect(files).to include('README.md')
      expect(files).to include('lib/some_gem.rb')
      expect(files).to include('bundle/bundler/setup.rb')
    end

    it 'should include gem build tool' do
      files = @packguy.gather_files

      expect(files).to include(Packguy.gem_build_extensions_path)
    end
  end
end
