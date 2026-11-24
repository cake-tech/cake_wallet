import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

class AskCakeDocsHit {
  const AskCakeDocsHit(this.excerpts, this.url);

  /// Passages to hand to the model.
  final String excerpts;

  /// The docs page the best passage came from; always shown to the user.
  final String url;
}

/// Keyword (BM25) search over the Cake Wallet docs bundled in
/// assets/ask_cake/docs_index.json. The model answers help questions only from
/// passages found here, so answers stay current with whatever docs ship in the
/// build. Rebuild the index with bench/ask_cake/docs/build_docs_index.py.
class AskCakeDocs {
  AskCakeDocs._(this._chunks, this._tf, this._idf, this._averageLength)
      : _titles = [for (final chunk in _chunks) _tokens(chunk['t'] as String).toSet()],
        _sections = [for (final chunk in _chunks) _tokens(chunk['s'] as String).toSet()];

  final List<Set<String>> _titles;
  final List<Set<String>> _sections;

  static const _assetPath = 'assets/ask_cake/docs_index.json';
  static const _minScore = 6.0;
  static const _maxWords = 480;
  static const _stop = {
    'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been', 'do', 'does', 'did', 'how', 'what', //
    'which', 'who', 'when', 'where', 'why', 'can', 'could', 'should', 'would', 'i', 'my', 'me', 'we', //
    'you', 'your', 'it', 'its', 'this', 'that', 'these', 'those', 'to', 'of', 'in', 'on', 'for', 'with', //
    'and', 'or', 'not', 'from', 'by', 'at', 'as', 'if', 'into', 'about', 'there', 'here', 'have', 'has', //
    'had', 'will', 'just', 'so', 'than', 'then', 'them', 'they', 'their', 'our', 'us', 'any', 'some', //
    'more', 'most', 'also',
  };

  final List<Map<String, dynamic>> _chunks;
  final List<(Map<String, int>, int)> _tf;
  final Map<String, double> _idf;
  final double _averageLength;

  static Future<AskCakeDocs>? _instance;

  static Future<AskCakeDocs> load() => _instance ??= _load();

  static Future<AskCakeDocs> _load() async {
    final decoded = jsonDecode(await rootBundle.loadString(_assetPath)) as Map<String, dynamic>;
    final chunks = (decoded['chunks'] as List).cast<Map<String, dynamic>>();
    final tf = <(Map<String, int>, int)>[];
    final df = <String, int>{};
    for (final chunk in chunks) {
      // Title and section words count three times.
      final heading = _tokens('${chunk['t']} ${chunk['s']}');
      final words = [..._tokens(chunk['x'] as String), ...heading, ...heading, ...heading];
      final counts = <String, int>{};
      for (final word in words) {
        counts[word] = (counts[word] ?? 0) + 1;
      }
      tf.add((counts, words.length));
      for (final word in counts.keys) {
        df[word] = (df[word] ?? 0) + 1;
      }
    }
    final n = chunks.length;
    final idf = df.map((word, d) => MapEntry(word, log(1 + (n - d + 0.5) / (d + 0.5))));
    final average = tf.fold<int>(0, (sum, entry) => sum + entry.$2) / max(1, n);
    return AskCakeDocs._(chunks, tf, idf, average);
  }

  /// "back up" and "backup", "e-mail" and "email" are the same word to a reader.
  static String _normalise(String text) => text
      .toLowerCase()
      .replaceAllMapped(RegExp(r'\bback(ed|ing|s)? up\b'), (_) => 'backup')
      .replaceAll(RegExp(r'\be-mail\b'), 'email');

  static List<String> _tokens(String text) => RegExp(r'[a-z0-9]+')
      .allMatches(_normalise(text))
      .map((m) => m.group(0)!)
      .where((w) => w.length > 1 && !_stop.contains(w))
      .map(_stem)
      .toList();

  static String _stem(String word) {
    for (final suffix in const ['ing', 'ed', 'es', 's']) {
      if (word.length > suffix.length + 3 && word.endsWith(suffix)) {
        return word.substring(0, word.length - suffix.length);
      }
    }
    return word;
  }

  /// Best passages for [query], or null when the docs have nothing relevant.
  AskCakeDocsHit? search(String query, {int count = 3}) {
    const k1 = 1.4;
    const b = 0.6;
    final terms = _tokens(query);
    final distinct = terms.toSet();
    final scored = <(double, int)>[];
    for (var i = 0; i < _chunks.length; i++) {
      final (counts, length) = _tf[i];
      var score = 0.0;
      for (final term in terms) {
        final f = counts[term];
        if (f == null) continue;
        score += (_idf[term] ?? 0) * f * (k1 + 1) / (f + k1 * (1 - b + b * length / _averageLength));
      }
      if (score <= 0) continue;
      // Passages that cover more of the question's words beat ones that repeat a single word.
      score *= 0.5 + distinct.where(counts.containsKey).length / max(1, distinct.length);
      // A page whose whole title is in the question ("Support", "Hardware wallet") is the page asked about.
      final title = _titles[i];
      if (title.isNotEmpty && distinct.containsAll(title)) score = score * 1.5 + 3;
      // A section whose heading is the question itself (FAQ entries) answers it directly.
      final section = _sections[i];
      if (section.isNotEmpty && section.containsAll(distinct) && section.length <= distinct.length + 2) {
        score = score * 1.3 + 2;
      }
      scored.add((score, i));
    }
    if (scored.isEmpty) return null;
    scored.sort((x, y) => y.$1.compareTo(x.$1));
    if (scored.first.$1 < _minScore) return null;

    final picked = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final (_, index) in scored) {
      final chunk = _chunks[index];
      if (!seen.add('${chunk['u']}#${chunk['s']}')) continue;
      picked.add(chunk);
      if (picked.length == count) break;
    }
    final top = picked.first;
    // Lead with the page's own introduction when the best passage is a sub-section.
    final intro = _chunks.where((c) => c['u'] == top['u'] && c['s'] == '').firstOrNull;
    final ordered = [if (intro != null && !identical(intro, top)) intro, ...picked];

    final parts = <String>[];
    final used = <String>{};
    var words = 0;
    for (final chunk in ordered) {
      if (!used.add('${chunk['u']}#${chunk['s']}')) continue;
      final text = (chunk['x'] as String).split(RegExp(r'\s+')).take(170).join(' ');
      words += text.split(' ').length;
      if (words > _maxWords && parts.isNotEmpty) break;
      final section = chunk['s'] as String;
      parts.add('[${chunk['t']}${section.isEmpty ? '' : ' / $section'}] $text');
    }
    return AskCakeDocsHit(parts.join('\n\n'), top['u'] as String);
  }
}
