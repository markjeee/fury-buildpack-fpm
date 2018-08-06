# Overview

This is a buildpack for creating Debian and RPM packages using
fpm. Primarily designed to run within Fury's build system. Supports building native extensions as a post-install step of the target package.

# How to use

Specify a custom buildpack in your .fury.yml as:

```
builds:
  - pack: https://github.com/markjeee/fury-buildpack-fpm
```

More information on how to specify a custom buildpack can be found on [Fury's help page](https://gemfury.com/help/customize-git-build/).

# Configurable options

You may specify additional options, as an environment variable that is set during build time.

```
builds:
  - pack: https://github.com/markjeee/fury-buildpack-fpm
    env:
      GEM_SPECFILE: "subpath_to/gemname.gemspec"
      PACKAGE_RUBY_VERSION: "2.3.0"
      PACKAGE_DEPENDENCIES: "mysql,mysql-dev,libxml++>=2.6"
      BUNDLE_GEMFILE: "$build/spec/gemfiles/Gemfile.19"
```

# Compatibility

This buildpack will detect for a gemspec file at the root path of your repo. And will use that to gather the files of your gems and other gem dependencies, then vendorized them to build the target package.

If a gem has native extensions, the extensions are not built at the time of building the package, but rather, a post-install script is included, that builds them right after the target package is installed in the system. If any native extensions requires other system libraries, you may specify additional package dependencies to be installed prior to installing the target package.

As of this version, this buildpack do not support packaging gems without a specific gemspec file.

# Limitations

The current build environment of the Fury platform is using `ruby 1.9.3p484`. If your gem or any dependencies has an explicit gemspec requirement of a later `ruby` version, they may fail. We are working in having a workaround for this limitation, but for the meantime, if you want to use this buildpack, you will have to remove the gemspec requirement.

Note, the build process will not load the code of your gem or the other dependencies. Only the code in the gemspec is loaded using the ruby version of the build environment. Please make sure the gemspec may be loaded properly, and additional code requirements are compatible.

# Contribution and Improvements

Please fork the code, make the changes, and submit a pull request for us to review your contributions.

## Feature requests

If you think it would be nice to have a particular feature that is presently not implemented, we would love to hear that and consider working on it. Just open an issue in Github.

# Questions

Please open a Github Issue if you have any other questions or problems.
