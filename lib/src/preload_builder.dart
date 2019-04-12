import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

const _preloadPlacholder = '<!--PRELOAD-HERE-->';

class PreloadBuilder extends Builder {
  final List<Glob> includeGlobs;
  final List<Glob> excludeGlobs;
  final bool debug;

  PreloadBuilder({
    Iterable<Glob> excludeGlobs,
    Iterable<Glob> includeGlobs,
    bool debug,
  })  : debug = debug ?? false,
        excludeGlobs = List<Glob>.unmodifiable(excludeGlobs ?? const <Glob>[]),
        includeGlobs = List<Glob>.unmodifiable(
            includeGlobs ?? <Glob>[Glob('web/**'), Glob('lib/**')]);

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    List<MapEntry<String, String>> debugLines;
    if (debug) {
      debugLines = <MapEntry<String, String>>[];
    }

    void logSkipReason(AssetId assetId, String reason) {
      debugLines?.add(MapEntry(assetId.path, reason));
    }

    Iterable<_PreloadEntry> assetIdToPreloadEntry(AssetId assetId) sync* {
      for (var excludeGlob in _excludeGlobs) {
        if (excludeGlob.matches(assetId.pathSegments.last)) {
          logSkipReason(assetId, 'matches "${excludeGlob.pattern}"');
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

    bool include(AssetId assetId) {
      for (var exclude in excludeGlobs) {
        if (exclude.matches(assetId.path)) {
          logSkipReason(assetId, 'excluded by glob "$exclude"');
          return false;
        }
      }
      return true;
    }

    final preloadSet = <_PreloadEntry>{};
    for (var glob in includeGlobs) {
      await for (var assetId in buildStep.findAssets(glob).where(include)) {
        preloadSet.addAll(assetIdToPreloadEntry(assetId));
      }
    }

    final preloads = preloadSet.toList()..sort();

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

const _excludeGlobStrings = {
  '*.dart',
  '*.dart.bootstrap.js',
  '*.dart.js.*',
  '*.dart2js.*',
  '*.dartdevc.*',
  '*.ddc.*',
  '*.digests',
  '*.html',
  '*.ico',
  '*.module.*',
  '*.ng_placeholder',
  '.*',
};

final _excludeGlobs =
    List<Glob>.unmodifiable(_excludeGlobStrings.map((v) => Glob(v)));

String _asValue(String fileName) {
  final extension = p.extension(fileName);
  switch (extension) {
    case '.js':
      return 'script';
    case '.otf':
    case '.ttf':
    case '.woff':
      return 'font';
    default:
      return 'fetch';
  }
}

class _PreloadEntry implements Comparable<_PreloadEntry> {
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

  @override
  bool operator ==(Object other) =>
      other is _PreloadEntry && other.href == href && other.asValue == asValue;

  @override
  int get hashCode => href.hashCode ^ asValue.hashCode;

  @override
  int compareTo(_PreloadEntry other) {
    final aSilly = (asValue == 'script') ? 0 : 1;
    final bSilly = (other.asValue == 'script') ? 0 : 1;

    var value = aSilly.compareTo(bSilly);

    if (value == 0) {
      value = href.compareTo(other.href);
    }
    return value;
  }
}
