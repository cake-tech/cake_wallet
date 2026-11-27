import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

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
  static const int _lineFeed = 0x0A;

  // A byte buffer rather than a List<int>: a List stores every byte in a
  // pointer-sized slot, so a large batch response would cost 8x its size.
  Uint8List _buffer = Uint8List(0);
  int _length = 0;

  // Bytes before this offset were already scanned and hold no newline, so the
  // next feed resumes here instead of rescanning the whole partial line.
  int _scanFrom = 0;

  /// Feeds newly received bytes and returns every complete line (decoded as
  /// UTF-8, without the trailing newline) found so far. Any trailing partial
  /// line is kept buffered for the next call.
  List<String> feed(List<int> bytes) {
    _append(bytes);

    final lines = <String>[];
    var lineStart = 0;
    for (var i = _scanFrom; i < _length; i++) {
      if (_buffer[i] != _lineFeed) {
        continue;
      }

      // Skip zero-length lines (i == lineStart). Malformed bytes are replaced
      // rather than thrown, so one bad line can't leave the buffer wedged and
      // throwing on every later feed.
      if (i > lineStart) {
        lines.add(
          utf8.decode(
            Uint8List.sublistView(_buffer, lineStart, i),
            allowMalformed: true,
          ),
        );
      }

      lineStart = i + 1;
    }

    // Drop everything up to and including the last newline; what remains is a
    // partial line, all of it already scanned.
    if (lineStart > 0) {
      _buffer.setRange(0, _length - lineStart, _buffer, lineStart);
      _length -= lineStart;
    }
    _scanFrom = _length;

    return lines;
  }

  void reset() {
    _length = 0;
    _scanFrom = 0;
  }

  void _append(List<int> bytes) {
    final needed = _length + bytes.length;
    if (needed > _buffer.length) {
      final grown = Uint8List(max(needed, _buffer.length * 2));
      grown.setRange(0, _length, _buffer);
      _buffer = grown;
    }

    _buffer.setRange(_length, needed, bytes);
    _length = needed;
  }
}
