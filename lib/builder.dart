// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
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

  return _WebBuilder(excludeGlobs: excludes, includeGlobs: includes);
}

const _preloadPlacholder = '<!--PRELOAD-HERE-->';

class _WebBuilder extends Builder {
  final List<Glob> _includeGlobs;
  final List<Glob> _excludeGlobs;

  _WebBuilder({
    Iterable<Glob> excludeGlobs,
    Iterable<Glob> includeGlobs,
  })  : _excludeGlobs = List<Glob>.unmodifiable(excludeGlobs ?? const <Glob>[]),
        _includeGlobs = List<Glob>.unmodifiable(
            includeGlobs ?? <Glob>[Glob('web/**'), Glob('lib/**')]);

  Stream<_PreloadEntry> _matchingAssets(BuildStep buildStep) async* {
    for (var glob in _includeGlobs) {
      yield* buildStep.findAssets(glob).where((assetId) {
        for (var exclude in _excludeGlobs) {
          if (exclude.matches(assetId.path)) {
            return false;
          }
        }
        return true;
      }).expand(_process);
    }
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final preloads = await _matchingAssets(buildStep).toList();

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

Iterable<_PreloadEntry> _process(AssetId assetId) sync* {
  for (var excludeEndsWith in _excludeEndsWith) {
    if (assetId.path.endsWith(excludeEndsWith)) {
      return;
    }
  }

  for (var excludeContains in _excludeContains) {
    if (assetId.path.contains(excludeContains)) {
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

  if (assetType != null) {
    yield _PreloadEntry(p.url.joinAll(segments), assetType);
  }
}

String _asValue(String fileName) {
  final extension = p.extension(fileName);
  switch (extension) {
    case '.js':
      return 'script';
    case '.ttf':
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
