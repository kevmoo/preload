import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:preload/builder.dart';
import 'package:preload/src/preload_builder.dart';
import 'package:test/test.dart';

void main() {
  group('builder config', () {
    test('defaults', () {
      final builder = buildPreload() as PreloadBuilder;
      expect(builder.debug, isFalse);
      expect(builder.excludeGlobs, isEmpty);
      expect(builder.includeGlobs, hasLength(2));
      expect(builder.includeGlobs,
          contains(isA<Glob>().having((e) => e.pattern, 'pattern', 'web/**')));
      expect(builder.includeGlobs,
          contains(isA<Glob>().having((e) => e.pattern, 'pattern', 'lib/**')));
    });

    test('configured', () {
      final builder = buildPreload(const BuilderOptions({
        'debug': true,
        'exclude': ['foo.js'],
        'include': [],
      })) as PreloadBuilder;
      expect(builder.debug, isTrue);
      expect(builder.includeGlobs, isEmpty);
      expect(builder.excludeGlobs, hasLength(1));
      expect(builder.excludeGlobs.single,
          isA<Glob>().having((e) => e.pattern, 'pattern', 'foo.js'));
    });
  });

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


  <script defer type="application/javascript" src="main.dart.js"></script>
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
        'pkg|lib/.DS_Store': '// some dot file',
        'pkg|lib/assets/json.json': '// some json',
        'pkg|web/main.dart.js.tar.gz': '// some tar.gz file',
        'pkg|web/assets/font.otf': '// some font',
        'pkg|web/assets/font.ttf': '// some font',
        'pkg|web/assets/font.woff': '// some font',
        'pkg|web/assets/image.jpg': '// some jpg',
        'pkg|web/assets/json.json': '// some json',
        'pkg|web/index.template.html': _htmlInputWithPreloadPlaceholder,
        'pkg|web/main.dart.js': '// some js',
      },
      outputs: {
        'pkg|web/index.html': r'''
<html>
<head>
  <link rel="preload" href="main.dart.js" as="script">
  <link rel="preload" href="assets/font.otf" as="font" crossorigin>
  <link rel="preload" href="assets/font.ttf" as="font" crossorigin>
  <link rel="preload" href="assets/font.woff" as="font" crossorigin>
  <link rel="preload" href="assets/image.jpg" as="fetch" crossorigin>
  <link rel="preload" href="assets/json.json" as="fetch" crossorigin>
  <link rel="preload" href="packages/pkg/assets/json.json" as="fetch" crossorigin>

  <script defer type="application/javascript" src="main.dart.js"></script>
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
        'pkg|lib/assets/json.json': '// some json, in lib',
        'pkg|web/assets/font.ttf': '// some font',
        'pkg|web/assets/image.jpg': '// some jpg',
        'pkg|web/assets/json.json': '// some json',
        'pkg|web/assets/txt.txt': '// some txt',
        'pkg|web/index.template.html': _htmlInputWithPreloadPlaceholder,
        'pkg|web/main.dart.js': '// some js',
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

  <script defer type="application/javascript" src="main.dart.js"></script>
</head>
</html>
''',
      },
    );
  });

  test('with debug enabled in options', () async {
    final logEntryies = <LogRecord>[];
    await testBuilder(
      buildPreload(const BuilderOptions({
        'exclude': ['**/*.txt'],
        'debug': true,
      })),
      {
        'pkg|lib/.DS_Store': '// some "." file',
        'pkg|lib/assets/json.json': '// some json, in lib',
        'pkg|web/assets/font.ttf': '// some font',
        'pkg|web/assets/image.jpg': '// some jpg',
        'pkg|web/assets/json.json': '// some json',
        'pkg|web/assets/txt.txt': '// some txt',
        'pkg|web/index.template.html': _htmlInputWithPreloadPlaceholder,
        'pkg|web/main.dart.js': '// some js',
      },
      onLog: logEntryies.add,
      outputs: {
        'pkg|web/index.html': r'''
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
''',
      },
    );

    expect(logEntryies, hasLength(1));
    expect(logEntryies.single.message, r'''
These items where excluded when generating preload tags:
  ASSET                   REASON
  lib/.DS_Store           starts with "."
  web/assets/txt.txt      excluded by glob "**/*.txt"
  web/index.template.html ends with ".html"
''');
  });

  test('with includes', () async {
    await testBuilder(
      buildPreload(const BuilderOptions({
        'include': ['**/*.txt'],
      })),
      {
        'pkg|lib/assets/txt.txt': '// some txt, in lib',
        'pkg|web/assets/font.ttf': '// some font',
        'pkg|web/assets/image.jpg': '// some jpg',
        'pkg|web/assets/json.json': '// some json',
        'pkg|web/assets/txt.txt': '// some txt',
        'pkg|web/index.template.html': _htmlInputWithPreloadPlaceholder,
        'pkg|web/main.dart.js': '// some js',
      },
      outputs: {
        'pkg|web/index.html': r'''
<html>
<head>
  <link rel="preload" href="assets/txt.txt" as="fetch" crossorigin>
  <link rel="preload" href="packages/pkg/assets/txt.txt" as="fetch" crossorigin>

  <script defer type="application/javascript" src="main.dart.js"></script>
</head>
</html>
''',
      },
    );
  });

  test('overlapping includes should not duplicate tags', () async {
    await testBuilder(
      buildPreload(const BuilderOptions({
        'include': ['**/*.txt', '**/*.txt'],
      })),
      {
        'pkg|lib/assets/txt.txt': '// some txt, in lib',
        'pkg|web/assets/font.ttf': '// some font',
        'pkg|web/assets/image.jpg': '// some jpg',
        'pkg|web/assets/json.json': '// some json',
        'pkg|web/assets/txt.txt': '// some txt',
        'pkg|web/index.template.html': _htmlInputWithPreloadPlaceholder,
        'pkg|web/main.dart.js': '// some js',
      },
      outputs: {
        'pkg|web/index.html': r'''
<html>
<head>
  <link rel="preload" href="assets/txt.txt" as="fetch" crossorigin>
  <link rel="preload" href="packages/pkg/assets/txt.txt" as="fetch" crossorigin>

  <script defer type="application/javascript" src="main.dart.js"></script>
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
        'pkg|lib/assets/json.json': '// some json, in lib',
        'pkg|web/assets/font.ttf': '// some font',
        'pkg|web/assets/image.jpg': '// some jpg',
        'pkg|web/assets/json.json': '// some json',
        'pkg|web/main.dart.js': '// some js',
        'pkg|web/index.template.html': r'''
<html>
  <head>
    <!--PRELOAD-HERE-->
  </head>
</html>
''',
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

  <script defer type="application/javascript" src="main.dart.js"></script>
</head>
</html>
''';

const _emptyHtmlInput = r'''
<html></html>
''';
