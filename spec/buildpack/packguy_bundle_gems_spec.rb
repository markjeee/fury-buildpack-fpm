require 'spec_helper'
require 'packguy'

describe 'Packguy bundle_gems' do
  context 'perform bundle_gems' do
    before do
      BuildpackSpec.packguy_setup
      @packguy = Packguy.new
      @prefix_path = @packguy.opts[:deb_prefix]
    end

    it 'should gather gems' do
      bgems = @packguy.bundle_gems

      expect(bgems).to include('highline')
      expect(bgems['highline'][:spec].name).to eq('highline')
    end

    it 'should identify files' do
      bgems = @packguy.bundle_gems

      highline = bgems['highline']
      expect(highline[:files]).not_to be_empty
      expect(highline[:files]).to include('lib/highline.rb')
    end

    it 'should add gem building tools' do
      bgems = @packguy.bundle_gems
    end
  end
end
