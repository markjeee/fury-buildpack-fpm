require_relative '../spec_helper'
require 'packguy'

describe 'Compile stage in Buildpack' do
  context 'passed with valid build path' do
    before do
      @build_path = BuildpackSpec::VALID_BUILD_PATH
    end

    it 'should compile' do
      success = BuildpackSpec.compile(@build_path,
                                      { 'TEST_NOBUILD' => 1 },
                                      no_stdout: true)
      expect(success).to eq(true)
    end

    it 'should compile with custom gemspec' do
      success = BuildpackSpec.compile(@build_path,
                                      { 'TEST_NOBUILD' => 1,
                                        'GEM_SPECFILE' => 'gemspecs/another.gemspec' },
                                      no_stdout: true)
      expect(success).to eq(true)
    end

    it 'should not compile with wrong gemspec' do
      success = BuildpackSpec.compile(@build_path,
                                      { 'TEST_NOBUILD' => 1,
                                        'GEM_SPECFILE' => 'gemspecs/donotexist.gemspec' },
                                      no_stdout: true)
      expect(success).to eq(false)
    end
  end

  context 'third-party gems' do
    before do
      unless ENV['INCLUDE_COMPILE_EXTRA_SPECS']
        skip 'Compile third party specs skipped, unless specified: env INCLUDE_COMPILE_EXTRA_SPECS=1'
      end

      BuildpackSpec::DownloadGems.check_and_download_gems_for_spec
    end

    BuildpackSpec.spec_gems.each do |gem_name, source_url|
      it 'should produce a package: %s' % gem_name do
        success = BuildpackSpec.compile_with_gems(gem_name)
        expect(success).to eq(true)
      end
    end
  end
end
