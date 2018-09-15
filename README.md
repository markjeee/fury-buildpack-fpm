# Overview

This is a buildpack for creating Debian and RPM packages using packtory. Designed to execute in Gemfury's build system, and release built packages for hosting in Gemfury's repository.

Support for building native extensions is available, using a post-install step of the target package.

# How to use

Specify a custom buildpack in your .fury.yml as:

```
builds:
  - pack: https://github.com/markjeee/fury-buildpack-packtory
```

By default, this will build a Debian package that is compatible to install in Ubuntu and Debian.

More information on how to specify a custom buildpack can be found on [Fury's help page](https://gemfury.com/help/customize-git-build/).

# Configurable options

You may specify additional options, as an environment variable that is set during build time.

```
builds:
  - pack: https://github.com/markjeee/fury-buildpack-packtory
    env:
      GEM_SPECFILE: "subpath_to/gemname.gemspec"
      BUNDLE_GEMFILE: "$build/spec/gemfiles/Gemfile.19"
      PACKAGE_RUBY_VERSION: "2.5.1"
      PACKAGE_DEPENDENCIES: "mysql,mysql-dev,libxml++>=2.6"
      PACKAGE_OUTPUT: "deb"
```

# Compatibility

If not specified, this buildpack will detect for a gemspec (\*.gemspec) file at the root path of your repo, then use that to gather the files of your gem and gem dependencies. After which, it vendorized all files to build the target package.

If a gem has native extensions, the extensions are not built at the time of building the package, but rather, a post-install script is included, that builds them right after the target package is installed in the system. If any native extensions requires other system libraries, you may specify additional package dependencies to be installed prior to installing the target package.

As of this version, this buildpack do not support packaging gems without a specific gemspec file.

# Limitations

Note, the build process will not load the code of your gem or the other dependencies. Only the code in the gemspec is loaded using the ruby version of the build environment. Please make sure the gemspec may be loaded properly, and additional code requirements are compatible.

# Contribution and Improvements

Please fork the code, make the changes, and submit a pull request for us to review your contributions.

## Feature requests

If you think it would be nice to have a particular feature that is presently not implemented, we would love to hear that and consider working on it. Just open an issue in Github.

# Questions

Please open a Github Issue if you have any other questions or problems.
