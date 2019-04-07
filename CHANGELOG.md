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
