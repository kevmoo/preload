![Pub](https://img.shields.io/pub/v/preload.svg)
[![Build Status](https://travis-ci.org/kevmoo/preload.svg?branch=master)](https://travis-ci.org/kevmoo/preload)

1. Add `preload` to `dev_dependencies` in `pubspec.yaml`.
   You should already have a dependency on `build_runner`.

    ```yaml
    name: my_pkg

    dev_dependencies:
      build_runner: ^1.0.0
      preload: ^1.0.0
    ```

2. Update the html in your `web` directory.

    1. Rename `index.html` to `index.template.html`.
    2. Add a place-holder for the preload entries.
   
   ```html
    <html>
    <head>
      <!--PRELOAD-HERE-->
      <script defer type="application/javascript" src="main.dart.js"></script>
    </head>
    </html>
    ```

2. Run a build.

    ```console
    > pub run build_runner build
    ```

    You should now see `index.html` generated with preloads defined.
    
    ```html
    <html>
    <head>
      <link rel="preload" href="main.dart.js" as="script">
      <link rel="preload" href="assets/font.ttf" as="font" crossorigin>
      <link rel="preload" href="assets/image.jpg" as="fetch" crossorigin>
      <link rel="preload" href="assets/json.json" as="fetch" crossorigin>
      <link rel="preload" href="packages/pkg/assets/json.json" as="fetch" crossorigin>
    
      <script defer type="application/javascript" src="main.dart.js"></script>
    </head>
    </html>
    ```

## `build.yaml` configuration

The builder also supports configuration values. Below are the supported keys
along with their defaults.

```yaml
debug: false
exclude: []
include:
- 'web/**'
- 'lib/**'
```
