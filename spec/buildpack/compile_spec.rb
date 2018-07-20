require 'spec_helper'

describe 'Compile stage in Buildpack' do
  context 'when invoked' do
    before do
      BuildpackSpec::DownloadGems.check_and_download_gems_for_spec
    end

    BuildpackSpec.spec_gems.each do |gem_name, source_url|
      it 'should produce a package: %s' % gem_name do
        success = BuildpackSpec.compile(gem_name)
        expect(success).to eq(true)
      end
    end
  end
end
