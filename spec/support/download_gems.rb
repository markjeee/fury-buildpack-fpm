require 'uri'
require 'fileutils'

module BuildpackSpec
  module DownloadGems
    def self.check_and_download_gems_for_spec
      BuildpackSpec.prepare_buildpack_spec_gems_path
      spec_gems = BuildpackSpec.spec_gems

      spec_gems.each do |gem_name, gem_source|
        gem_file_path = stream_download(gem_name, gem_source)

        extract_path = BuildpackSpec.spec_gem_extract_path(gem_name)
        unless File.exists?(extract_path)
          FileUtils.rm_rf(extract_path)
          FileUtils.mkpath(extract_path)

          cmd = 'tar -xzp --strip-components 1 -C %s -f %s' % [ extract_path, gem_file_path ]
          system(cmd)
        end
      end
    end

    def self.stream_download(gem_name, url)
      u = URI.parse(url)

      dest_file = BuildpackSpec.spec_gem_archive_path(gem_name)
      unless File.exists?(dest_file)
        cmd = 'curl -sLo %s %s' % [ dest_file, url ]
        system(cmd)
      end

      dest_file
    end
  end
end
