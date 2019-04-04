/// Configuration for using `package:build`-compatible build systems.
///
/// This library is **not** intended to be imported by typical end-users unless
/// you are creating a custom compilation pipeline.
///
/// See [package:build_runner](https://pub.dartlang.org/packages/build_runner)
/// for more information.
library builder;

import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

Builder buildPreload([BuilderOptions options]) {
  options ??= const BuilderOptions({});

  List<Glob> excludes;
  if (options.config.containsKey('exclude')) {
    excludes = (options.config['exclude'] as List)
        .cast<String>()
        .map((v) => Glob(v))
        .toList();
  }

  List<Glob> includes;
  if (options.config.containsKey('include')) {
    includes = (options.config['include'] as List)
        .cast<String>()
        .map((v) => Glob(v))
        .toList();
  }

  bool debug;
  if (options.config.containsKey('debug')) {
    debug = options.config['debug'] as bool;
  }

  return _WebBuilder(
    excludeGlobs: excludes,
    includeGlobs: includes,
    debug: debug,
  );
}

const _preloadPlacholder = '<!--PRELOAD-HERE-->';

class _WebBuilder extends Builder {
  final List<Glob> _includeGlobs;
  final List<Glob> _excludeGlobs;
  final bool _debug;

  _WebBuilder({
    Iterable<Glob> excludeGlobs,
    Iterable<Glob> includeGlobs,
    bool debug,
  })  : _debug = debug ?? false,
        _excludeGlobs = List<Glob>.unmodifiable(excludeGlobs ?? const <Glob>[]),
        _includeGlobs = List<Glob>.unmodifiable(
            includeGlobs ?? <Glob>[Glob('web/**'), Glob('lib/**')]);

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    List<MapEntry<String, String>> debugLines;
    if (_debug) {
      debugLines = <MapEntry<String, String>>[];
    }

    void logSkipReason(AssetId assetId, String reason) {
      debugLines?.add(MapEntry(assetId.path, reason));
    }

    Iterable<_PreloadEntry> assetIdToPreloadEntry(AssetId assetId) sync* {
      for (var excludeEndsWith in _excludeEndsWith) {
        if (assetId.path.endsWith(excludeEndsWith)) {
          logSkipReason(assetId, 'ends with "$excludeEndsWith"');
          return;
        }
      }

      for (var excludeContains in _excludeContains) {
        if (assetId.path.contains(excludeContains)) {
          logSkipReason(assetId, 'contains "$excludeContains"');
          return;
        }
      }

      var segments = assetId.pathSegments;

      if (segments[0] == 'web') {
        segments = segments.skip(1).toList();
      } else if (segments[0] == 'lib') {
        segments = ['packages', assetId.package]..addAll(segments.skip(1));
      } else {
        throw UnimplementedError('not ready to party on `$segments` yet.');
      }

      final assetType = _asValue(segments.last);
      yield _PreloadEntry(p.url.joinAll(segments), assetType);
    }

    Stream<_PreloadEntry> matchingAssets(BuildStep buildStep) async* {
      for (var glob in _includeGlobs) {
        yield* buildStep.findAssets(glob).where((assetId) {
          for (var exclude in _excludeGlobs) {
            if (exclude.matches(assetId.path)) {
              logSkipReason(assetId, 'excluded by glob "$exclude"');
              return false;
            }
          }
          return true;
        }).expand(assetIdToPreloadEntry);
      }
    }

    final preloads = await matchingAssets(buildStep).toList();

    if (debugLines?.isNotEmpty ?? false) {
      final longest = debugLines.fold<int>(0, (longest, value) {
        if (value.key.length > longest) {
          longest = value.key.length;
        }
        return longest;
      });

      debugLines.sort((a, b) => a.key.compareTo(b.key));

      final linesString = debugLines
          .map((e) => '${e.key.padRight(longest)} ${e.value}')
          .join('\n  ');

      log.warning('''
These items where excluded when generating preload tags:
  ${"ASSET".padRight(longest)} REASON
  $linesString
''');
    }

    final templateContent = await buildStep.readAsString(buildStep.inputId);

    preloads.sort((a, b) {
      final aSilly = (a.asValue == 'script') ? 0 : 1;
      final bSilly = (b.asValue == 'script') ? 0 : 1;

      var value = aSilly.compareTo(bSilly);

      if (value == 0) {
        value = a.href.compareTo(b.href);
      }
      return value;
    });

    final outputContent = templateContent.replaceFirstMapped(
      RegExp('([\\t ]*)(${RegExp.escape(_preloadPlacholder)})'),
      (match) {
        final indent = match[1];
        return preloads.map((e) => '$indent$e').join('\n');
      },
    );

    final newAssetId = AssetId(
      buildStep.inputId.package,
      //TODO: be a bit more paranoid here and make sure it's just the end
      buildStep.inputId.path.replaceAll('.template.html', '.html'),
    );

    await buildStep.writeAsString(
      newAssetId,
      outputContent,
    );
  }

  @override
  final buildExtensions = const {
    r'web/index.template.html': ['web/index.html']
  };
}

const _excludeContains = [
  '.dart2js.',
  '.dartdevc.',
  '.ddc.js',
];

const _excludeEndsWith = [
  '.dart',
  '.dart.bootstrap.js',
  '.digests',
  '.html',
  '.ico',
  '.module.library',
];

String _asValue(String fileName) {
  final extension = p.extension(fileName);
  switch (extension) {
    case '.js':
      return 'script';
    case '.ttf':
    case '.woff':
      return 'font';
    default:
      return 'fetch';
  }
}

class _PreloadEntry {
  final String href;
  final String asValue;

  String get _crossOrigin {
    if (!p.url.isAbsolute(href) && asValue == 'script') {
      return '';
    }
    return ' crossorigin';
  }

  _PreloadEntry(this.href, this.asValue);

  @override
  String toString() =>
      '<link rel="preload" href="$href" as="$asValue"$_crossOrigin>';
}
