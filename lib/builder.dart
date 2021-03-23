/// Configuration for using `package:build`-compatible build systems.
///
/// This library is **not** intended to be imported by typical end-users unless
/// you are creating a custom compilation pipeline.
///
/// See [package:build_runner](https://pub.dev/packages/build_runner)
/// for more information.
library builder;

import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'src/preload_builder.dart';

Builder buildPreload([BuilderOptions? options]) {
  options ??= const BuilderOptions({});

  List<Glob>? excludes;
  if (options.config.containsKey('exclude')) {
    excludes = (options.config['exclude'] as List)
        .cast<String>()
        .map((v) => Glob(v))
        .toList();
  }

  List<Glob>? includes;
  if (options.config.containsKey('include')) {
    includes = (options.config['include'] as List)
        .cast<String>()
        .map((v) => Glob(v))
        .toList();
  }

  bool? debug;
  if (options.config.containsKey('debug')) {
    debug = options.config['debug'] as bool;
  }

  return PreloadBuilder(
    excludeGlobs: excludes,
    includeGlobs: includes,
    debug: debug,
  );
}
