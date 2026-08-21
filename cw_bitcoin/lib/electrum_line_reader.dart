import 'dart:convert';

/// Reassembles a stream of raw socket bytes into complete newline-delimited
/// JSON-RPC messages, buffering any partial trailing bytes across calls.
///
/// Decoding a chunk before we know it ends cleanly isn't safe - it can throw
/// on a split character, or quietly turn a stray fragment into something
/// that just looks like valid JSON, corrupting the message it came from.
///
/// That's why we scan for `\n` (0x0A) in the raw bytes instead of decoding
/// each chunk to text first.
class ElectrumLineReader {
  final List<int> _buffer = <int>[];

  /// Feeds newly received bytes and returns every complete line (decoded as
  /// UTF-8, without the trailing newline) found so far. Any trailing partial
  /// line is kept buffered for the next call.
  List<String> feed(List<int> bytes) {
    _buffer.addAll(bytes);

    final newlines = <String>[];
    var previousNewlineStart = 0;
    for (var i = 0; i < _buffer.length; i++) {
      if (_buffer[i] == 0x0A) {
        // Decode only the bytes between the previous newline and this one -
        // each is a self-contained message, so decoding line-by-line (rather
        // than the whole buffer at once) avoids re-decoding already-emitted
        // bytes on every `feed` call. Skip zero-length lines (i == start).
        if (i > previousNewlineStart) {
          newlines.add(utf8.decode(_buffer.sublist(previousNewlineStart, i)));
        }

        previousNewlineStart = i + 1;
      }
    }

    // Drop everything up to and including the last newline found; whatever
    // remains is a partial line and must stay buffered for the next `feed`
    // call. `start` is only 0 when no newline was found this call, in which
    // case there's nothing complete to remove yet.
    if (previousNewlineStart > 0) {
      _buffer.removeRange(0, previousNewlineStart);
    }

    return newlines;
  }

  void reset() => _buffer.clear();
}
