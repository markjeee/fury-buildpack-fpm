require 'spec_helper'
require 'packguy'

describe 'Packguy' do
  context 'setup' do
    before do
      BuildpackSpec.packguy_setup
      @packguy = Packguy.new
    end

    it 'found a gemfile' do
      expect(@packguy.gemfile).not_to be_nil
    end

    it 'found a gemspec_file' do
      expect(@packguy.gemspec_file).not_to be_nil
    end

    it 'load gemspec' do
      expect(@packguy.gemspec.name).to eq('some_gem')
    end

    it 'set default packages' do
      expect(@packguy.opts[:packages]).to include(:deb)
      expect(@packguy.opts[:packages]).to include(:rpm)
    end

    it 'set ruby as a dependency' do
      expect(@packguy.opts[:dependencies]).to include('ruby')
    end
  end

  context 'custom gemfile' do
    before do
      opts = {
        :gemfile => File.join(BuildpackSpec::VALID_BUILD_PATH, 'custom_gemfile/Gemfile')
      }

      BuildpackSpec.packguy_setup(opts)
      @packguy = Packguy.new
    end

    it 'use custom gemspec' do
      expect(File.basename(@packguy.gemspec_file)).to eq('custom1.gemspec')
    end

    it 'load custom gemspec' do
      expect(@packguy.gemspec.name).to eq('custom1_gem')
    end
  end

  context 'custom gemspec' do
    before do
      opts = {
        :gemspec => File.join(BuildpackSpec::VALID_BUILD_PATH, 'gemspecs/another.gemspec')
      }

      BuildpackSpec.packguy_setup(opts)
      @packguy = Packguy.new
    end

    it 'load custom gemspec file' do
      expect(@packguy.gemspec.name).to eq('some_other_gem')
    end
  end

  context 'prepare' do
    it 'should gather files' do
      skip 'TODO'
    end

    it 'should prepare files' do
      skip 'TODO'
    end
  end

  context 'package' do
    it 'should build package' do
      skip 'TODO'
    end
  end
end
