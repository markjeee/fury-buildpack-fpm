require 'bundler/resolver/spec_group'
require 'bundler/installer'

class Packguy
  module PatchBundlerNoMetadataDeps
    def self.patch!
      Bundler::Resolver::SpecGroup.class_eval do
        alias :metadata_dependencies_without_patch :metadata_dependencies

        def metadata_dependencies(spec, platform); return []; end
      end

      Bundler::Installer.class_eval do
        alias :ensure_specs_are_compatible_without_path! :ensure_specs_are_compatible!

        def ensure_specs_are_compatible!; end
      end
    end
  end
end
