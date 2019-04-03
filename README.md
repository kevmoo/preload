![Pub](https://img.shields.io/pub/v/preload.svg)
[![Build Status](https://travis-ci.org/kevmoo/preload.svg?branch=master)](https://travis-ci.org/kevmoo/preload)

1. Add `build_version` to `pubspec.yaml`. Also make sure there is a `version`
   field.

    ```yaml
    name: my_pkg

    dev_dependencies:
      build_runner: ^1.0.0
      preload: ^1.0.0
    ```

2. Something something in the web directory...

2. Run a build.

    ```console
    > pub run build_runner build
    ```
