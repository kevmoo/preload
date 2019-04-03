import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:preload/builder.dart';
import 'package:test/test.dart';

void main() {
  test('no template section', () async {
    await testBuilder(
      buildPreload(),
      {
        'pkg|web/index.template.html': _emptyHtmlInput,
      },
      outputs: {
        'pkg|web/index.html': _emptyHtmlInput,
      },
    );
  });

  test('no template section', () async {
    await testBuilder(
      buildPreload(),
      {
        'pkg|web/index.template.html': _htmlInputWithPreloadPlaceholder,
      },
      outputs: {
        'pkg|web/index.html': r'''
<html>
<head>

</head>
</html>
''',
      },
    );
  });

  test('with files', () async {
    await testBuilder(
      buildPreload(),
      {
        'pkg|web/index.template.html': _htmlInputWithPreloadPlaceholder,
        'pkg|web/main.dart.js': '// some js',
        'pkg|web/assets/image.jpg': '// some jpg',
        'pkg|web/assets/font.ttf': '// some font',
        'pkg|web/assets/json.json': '// some json',
        'pkg|lib/assets/json.json': '// some json',
      },
      outputs: {
        'pkg|web/index.html': r'''
<html>
<head>
  <link rel="preload" href="main.dart.js" as="script">
  <link rel="preload" href="assets/font.ttf" as="font" crossorigin>
  <link rel="preload" href="assets/image.jpg" as="fetch" crossorigin>
  <link rel="preload" href="assets/json.json" as="fetch" crossorigin>
  <link rel="preload" href="packages/pkg/assets/json.json" as="fetch" crossorigin>
</head>
</html>
''',
      },
    );
  });

  test('with excludes', () async {
    await testBuilder(
      buildPreload(const BuilderOptions({
        'exclude': ['**/*.txt'],
      })),
      {
        'pkg|web/index.template.html': _htmlInputWithPreloadPlaceholder,
        'pkg|web/main.dart.js': '// some js',
        'pkg|web/assets/image.jpg': '// some jpg',
        'pkg|web/assets/font.ttf': '// some font',
        'pkg|web/assets/json.json': '// some json',
        'pkg|web/assets/txt.txt': '// some txt',
        'pkg|lib/assets/json.json': '// some json, in lib',
      },
      outputs: {
        'pkg|web/index.html': r'''
<html>
<head>
  <link rel="preload" href="main.dart.js" as="script">
  <link rel="preload" href="assets/font.ttf" as="font" crossorigin>
  <link rel="preload" href="assets/image.jpg" as="fetch" crossorigin>
  <link rel="preload" href="assets/json.json" as="fetch" crossorigin>
  <link rel="preload" href="packages/pkg/assets/json.json" as="fetch" crossorigin>
</head>
</html>
''',
      },
    );
  });

  test('with includes', () async {
    await testBuilder(
      buildPreload(const BuilderOptions({
        'include': ['**/*.txt'],
      })),
      {
        'pkg|web/index.template.html': _htmlInputWithPreloadPlaceholder,
        'pkg|web/main.dart.js': '// some js',
        'pkg|web/assets/image.jpg': '// some jpg',
        'pkg|web/assets/font.ttf': '// some font',
        'pkg|web/assets/json.json': '// some json',
        'pkg|web/assets/txt.txt': '// some txt',
        'pkg|lib/assets/txt.txt': '// some txt, in lib',
      },
      outputs: {
        'pkg|web/index.html': r'''
<html>
<head>
  <link rel="preload" href="assets/txt.txt" as="fetch" crossorigin>
  <link rel="preload" href="packages/pkg/assets/txt.txt" as="fetch" crossorigin>
</head>
</html>
''',
      },
    );
  });

  test('with custom indent', () async {
    await testBuilder(
      buildPreload(),
      {
        'pkg|web/index.template.html': r'''
<html>
  <head>
    <!--PRELOAD-HERE-->
  </head>
</html>
''',
        'pkg|web/main.dart.js': '// some js',
        'pkg|web/assets/image.jpg': '// some jpg',
        'pkg|web/assets/font.ttf': '// some font',
        'pkg|web/assets/json.json': '// some json',
        'pkg|lib/assets/json.json': '// some json, in lib',
      },
      outputs: {
        'pkg|web/index.html': r'''
<html>
  <head>
    <link rel="preload" href="main.dart.js" as="script">
    <link rel="preload" href="assets/font.ttf" as="font" crossorigin>
    <link rel="preload" href="assets/image.jpg" as="fetch" crossorigin>
    <link rel="preload" href="assets/json.json" as="fetch" crossorigin>
    <link rel="preload" href="packages/pkg/assets/json.json" as="fetch" crossorigin>
  </head>
</html>
''',
      },
    );
  });
}

const _htmlInputWithPreloadPlaceholder = r'''
<html>
<head>
  <!--PRELOAD-HERE-->
</head>
</html>
''';

const _emptyHtmlInput = r'''
<html></html>
''';
