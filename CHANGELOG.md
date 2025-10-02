## 2.1.0

- Require `build: ^4.0.0`.
- Require Dart SDK 3.9
- Added `preload.dart`. Deprecated `builder.dart`.
  Moving beyond this convention.

## 2.0.1

- Require `build: ^3.0.0`.
- Require Dart SDK 3.7

## 2.0.0

- Require at least Dart SDK `2.7.0`.
- Require `package:build` `1.0.0` or greater.

## 1.1.6

- Support the latest `package:build_config`.

## 1.1.5

- Exclude `*.ddc.*` and `*.digests` files.

## 1.1.4

- Exclude assets that end with `.dart.js.tar.gz`
  (`package:build_web_compilers` implementation).

## 1.1.3

- Preload `.otf` files as `"font"`. 

## 1.1.2

- Exclude assets that end with `.g.part` (from `package:source_gen`).
- Exclude assets that end with `.ng_placeholder` (from `package:angular`).

## 1.1.1

- Don't emit the same tag twice if there are `include` globs with overlapping
  matches.

## 1.1.0

- Make sure to run after `.dart.js` files are generated.
- Add `debug` option to print out all files that are excluded and why.
- Exclude files beginning with `.`.

## 1.0.1

- Preload `.woff` files as `"font"`. 

## 1.0.0

- Initial release.
