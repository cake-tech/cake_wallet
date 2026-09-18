import 'package:path/path.dart' as p;

/// Resolves an archive [entryName] to a path under [basePath].
///
/// Throws [FormatException] before any write when the entry is absolute,
/// contains a `..` segment in either path syntax, or resolves outside the base.
String resolveSafeArchivePath(String basePath, String entryName) {
  for (final style in [p.posix, p.windows]) {
    if (style.isAbsolute(entryName)) {
      throw FormatException(
          'Unsafe backup archive entry "$entryName": absolute paths are not allowed');
    }
    for (final segment in style.split(entryName)) {
      if (segment == '..') {
        throw FormatException(
            'Unsafe backup archive entry "$entryName": ".." traversal is not allowed');
      }
    }
  }

  final normalizedBase = p.normalize(basePath);
  final target = p.normalize(p.join(basePath, entryName));
  if (!p.isWithin(normalizedBase, target)) {
    throw FormatException(
        'Unsafe backup archive entry "$entryName" resolves outside "$normalizedBase"');
  }
  return target;
}
