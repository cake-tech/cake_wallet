import 'dart:convert';

import 'package:flutter/services.dart';

/// Byte-level BPE tokenizer for the bundled router model (SmolLM2 vocabulary).
///
/// It reproduces the Hugging Face `ByteLevel` + `BPE` pipeline exactly, so the
/// token ids the app feeds the model are the ones it was trained on.
class AskCakeRouterTokenizer {
  AskCakeRouterTokenizer(List<String> vocab, List<List<String>> merges, Map<String, int> special)
      : _vocab = vocab,
        _special = special {
    for (var i = 0; i < vocab.length; i++) {
      _ids[vocab[i]] = i;
    }
    for (var i = 0; i < merges.length; i++) {
      _ranks['${merges[i][0]} ${merges[i][1]}'] = i;
    }
    // GPT-2's printable stand-ins for the 256 byte values.
    final printable = <int>[
      for (var b = 0x21; b <= 0x7e; b++) b,
      for (var b = 0xa1; b <= 0xac; b++) b,
      for (var b = 0xae; b <= 0xff; b++) b,
    ];
    var next = 0;
    for (var b = 0; b < 256; b++) {
      final code = printable.contains(b) ? b : 256 + next++;
      _byteToChar[b] = String.fromCharCode(code);
      _charToByte[code] = b;
    }
  }

  factory AskCakeRouterTokenizer.fromJson(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    return AskCakeRouterTokenizer(
      (data['vocab'] as List).cast<String>(),
      (data['merges'] as List).map((m) => (m as List).cast<String>()).toList(),
      (data['special'] as Map).cast<String, int>(),
    );
  }

  static Future<AskCakeRouterTokenizer> load() async =>
      AskCakeRouterTokenizer.fromJson(await rootBundle.loadString('assets/ask_cake/router_tokenizer.json'));

  final List<String> _vocab;
  final Map<String, int> _special;
  final Map<String, int> _ids = {};
  final Map<String, int> _ranks = {};
  final Map<int, String> _byteToChar = {};
  final Map<int, int> _charToByte = {};
  final Map<String, List<int>> _cache = {};

  static final _pieces = RegExp(
      r"'s|'t|'re|'ve|'m|'ll|'d| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+",
      unicode: true);

  int get endOfTurn => _special['<|im_end|>']!;

  int get endOfText => _special['<|endoftext|>']!;

  List<int> encode(String text) {
    final out = <int>[];
    final specials = _special.keys.where(text.contains).toList();
    if (specials.isEmpty) {
      _encodePlain(text, out);
      return out;
    }
    final splitter = RegExp(specials.map(RegExp.escape).join('|'));
    var start = 0;
    for (final match in splitter.allMatches(text)) {
      _encodePlain(text.substring(start, match.start), out);
      out.add(_special[match.group(0)!]!);
      start = match.end;
    }
    _encodePlain(text.substring(start), out);
    return out;
  }

  void _encodePlain(String text, List<int> out) {
    for (final match in _pieces.allMatches(text)) {
      final piece = match.group(0)!;
      out.addAll(_cache[piece] ??= _bpe(piece));
    }
  }

  List<int> _bpe(String piece) {
    var parts = [for (final b in utf8.encode(piece)) _byteToChar[b]!];
    while (parts.length > 1) {
      var best = -1;
      var bestRank = 1 << 30;
      for (var i = 0; i < parts.length - 1; i++) {
        final rank = _ranks['${parts[i]} ${parts[i + 1]}'];
        if (rank != null && rank < bestRank) {
          bestRank = rank;
          best = i;
        }
      }
      if (best < 0) break;
      final first = parts[best];
      final second = parts[best + 1];
      final merged = <String>[];
      for (var i = 0; i < parts.length; i++) {
        if (i < parts.length - 1 && parts[i] == first && parts[i + 1] == second) {
          merged.add(first + second);
          i++;
        } else {
          merged.add(parts[i]);
        }
      }
      parts = merged;
    }
    return [for (final p in parts) _ids[p]!];
  }

  /// Text for generated ids; special tokens are dropped.
  String decode(List<int> ids) {
    final bytes = <int>[];
    for (final id in ids) {
      if (id < 0 || id >= _vocab.length || _special.containsValue(id)) continue;
      for (final unit in _vocab[id].runes) {
        final b = _charToByte[unit];
        if (b != null) bytes.add(b);
      }
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
}

/// What the router understood: one capability name plus whatever details the
/// user gave. It is a proposal only; guards and grounding run on it afterwards.
typedef AskCakeLabel = Map<String, dynamic>;

/// Chooses a capability and extracts its details for one user message.
abstract class AskCakeRouter {
  /// Null when the router cannot run on this device (no model file, old OS).
  /// [path] is the model package to load; without it the developer copy is used.
  Future<String?> prepare({String? path});

  Future<AskCakeLabel> route({
    required String coin,
    required List<String> earlier,
    required String message,
    String? pendingTool,
  });

  Future<void> release();
}

/// The text the router was trained on: up to three earlier user messages, an
/// optional note that the app is waiting for details, then the new message.
/// Addresses and invoices are replaced with a placeholder first.
String askCakeRouterPrompt(List<String> earlier, String? pendingTool, String message) {
  final recent = earlier.length > 3 ? earlier.sublist(earlier.length - 3) : earlier;
  return [
    for (final e in recent) '[earlier] ${askCakeMaskAddresses(e)}',
    if (pendingTool != null) '[assistant asked for missing details of: $pendingTool]',
    '[now] ${askCakeMaskAddresses(message)}',
  ].join('\n');
}

final _alphanumeric = RegExp(r'^[A-Za-z0-9]+$');
final _lightning = RegExp(r'^ln(bc|tb|url)[a-z0-9]{8,}$', caseSensitive: false);

String askCakeMaskAddresses(String text) => text.split(' ').map((word) {
      final core = word.replaceAll(RegExp(r'^[,.;:!?]+|[,.;:!?]+$'), '');
      final isAddress = core.length >= 26 && _alphanumeric.hasMatch(core) && RegExp(r'\d').hasMatch(core);
      return core.isNotEmpty && (isAddress || _lightning.hasMatch(core)) ? word.replaceAll(core, '[address]') : word;
    }).join(' ');

String askCakeRouterChat(String coin, String prompt) =>
    '<|im_start|>system\nYou route messages in the Cake Wallet app. Wallet coin: $coin. Reply with JSON only.<|im_end|>\n'
    '<|im_start|>user\n$prompt<|im_end|>\n<|im_start|>assistant\n';

/// The fine-tuned SmolLM2 router, run through Core ML by ios/Runner/AskCakeModel.swift.
class CoreMlAskCakeRouter implements AskCakeRouter {
  static const _channel = MethodChannel('com.cake_wallet/ask_cake');

  AskCakeRouterTokenizer? _tokenizer;
  bool _loaded = false;

  /// Milliseconds the last model load took, for the developer screens.
  int? lastLoadMs;

  /// Whether the last request ran on the Neural Engine copy (the CPU copy answers until it is ready).
  bool usingNeuralEngine = false;

  /// Running totals for the developer screens: requests routed, time spent in
  /// the model call, and time spent in Dart (tokenising, decoding, parsing).
  int calls = 0;
  int modelMicros = 0;
  int dartMicros = 0;

  String get stats => calls == 0
      ? 'router: no requests yet'
      : 'router: $calls requests, model ${(modelMicros / calls / 1000).toStringAsFixed(0)} ms each, '
          'Dart side ${(dartMicros / calls / 1000).toStringAsFixed(2)} ms each, load ${lastLoadMs ?? '-'} ms, '
          '${usingNeuralEngine ? 'Neural Engine' : 'CPU'}';

  @override
  Future<String?> prepare({String? path}) async {
    if (_loaded) return null;
    try {
      final info =
          await _channel.invokeMapMethod<String, dynamic>('routerLoad', {if (path != null) 'path': path}) ?? {};
      if (info['loaded'] != true) return info['reason'] as String? ?? 'unavailable';
      lastLoadMs = info['loadMs'] as int?;
      _tokenizer ??= await AskCakeRouterTokenizer.load();
      _loaded = true;
      return null;
    } on MissingPluginException {
      return 'unsupportedPlatform';
    } on PlatformException catch (e) {
      return e.code;
    }
  }

  @override
  Future<AskCakeLabel> route({
    required String coin,
    required List<String> earlier,
    required String message,
    String? pendingTool,
  }) async {
    final tokenizer = _tokenizer!;
    final dart = Stopwatch()..start();
    final ids = tokenizer.encode(askCakeRouterChat(coin, askCakeRouterPrompt(earlier, pendingTool, message)));
    dart.stop();
    final model = Stopwatch()..start();
    final output = await _channel.invokeMapMethod<String, dynamic>('routerGenerate', {
          'ids': ids,
          'stops': [tokenizer.endOfTurn, tokenizer.endOfText],
          'maxNew': 80,
        }) ??
        const {};
    model.stop();
    dart.start();
    final generated = (output['ids'] as List? ?? const []).cast<int>();
    final probabilities = (output['conf'] as List? ?? const []).cast<num>();
    usingNeuralEngine = output['fast'] == true;
    final label = parse(tokenizer.decode(generated));
    final confidence = toolConfidence(tokenizer, generated, probabilities);
    if (confidence != null) label['_conf'] = confidence;
    dart.stop();
    calls++;
    modelMicros += model.elapsedMicroseconds;
    dartMicros += dart.elapsedMicroseconds;
    return label;
  }

  /// How sure the model was of the capability it named: the lowest probability
  /// it gave any token up to the end of the tool name. Null when the model
  /// file does not report probabilities.
  static double? toolConfidence(AskCakeRouterTokenizer tokenizer, List<int> ids, List<num> probabilities) {
    if (probabilities.length < ids.length || ids.isEmpty) return null;
    final named = RegExp(r'^\s*\{"tool":\s*"[a-z_]+"');
    var lowest = 1.0;
    for (var i = 0; i < ids.length; i++) {
      if (probabilities[i] < lowest) lowest = probabilities[i].toDouble();
      if (named.hasMatch(tokenizer.decode(ids.sublist(0, i + 1)))) return lowest;
    }
    return lowest;
  }

  /// Anything that is not a JSON object with a tool name counts as "no idea".
  static AskCakeLabel parse(String raw) {
    try {
      final decoded = jsonDecode(raw.trim());
      if (decoded is Map<String, dynamic> && decoded['tool'] is String) return decoded;
    } on FormatException {
      // fall through
    }
    return {'tool': 'general_question', '_bad': raw};
  }

  @override
  Future<void> release() async {
    if (!_loaded) return;
    _loaded = false;
    await _channel.invokeMethod<void>('routerUnload');
  }
}
