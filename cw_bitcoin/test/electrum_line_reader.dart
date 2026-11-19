import "dart:convert";
import "dart:io";
import "dart:math";

import "package:cw_bitcoin/electrum_line_reader.dart";
import "package:flutter_test/flutter_test.dart";

String _readFixtureHex(String name) => File("test/fixtures/$name").readAsStringSync().trim();

/// Wraps a raw tx hex as a realistic Electrum `blockchain.transaction.get`
/// JSON-RPC response line, exactly as the server would send it.
String _rpcLine(String hex) => '{"jsonrpc":"2.0","id":"1","result":"$hex"}\n';

List<List<int>> _splitBytes(List<int> bytes, List<int> chunkSizes) {
  // resulting chunks, in order
  final chunks = <List<int>>[];
  // position in `bytes` where the next chunk starts
  var offset = 0;
  // index into `chunkSizes`
  var i = 0;
  while (offset < bytes.length) {
    // cycle through chunkSizes repeatedly
    final size = chunkSizes[i % chunkSizes.length];
    // clamp so the last chunk doesn't overrun `bytes`
    final end = (offset + size).clamp(0, bytes.length);
    // slice out the current chunk
    chunks.add(bytes.sublist(offset, end));

    // advance past the chunk just added
    offset = end;
    // move to the next chunk size for next iteration
    i++;
  }
  return chunks;
}

void main() {
  group("ElectrumLineReader", () {
    test("returns a complete line delivered in a single chunk", () {
      final reader = ElectrumLineReader();
      final lines = reader.feed(utf8.encode('{"id":"1"}\n'));
      expect(lines, ['{"id":"1"}']);
    });

    test("buffers a partial line across chunks with no newline yet", () {
      final reader = ElectrumLineReader();
      expect(reader.feed(utf8.encode('{"id":"1"')), isEmpty);
      expect(reader.feed(utf8.encode('}\n')), ['{"id":"1"}']);
    });

    test("splits multiple messages delivered in one chunk", () {
      final reader = ElectrumLineReader();
      final lines = reader.feed(utf8.encode('{"id":"1"}\n{"id":"2"}\n'));
      expect(lines, ['{"id":"1"}', '{"id":"2"}']);
    });

    test("handles a message split byte-by-byte across many chunks", () {
      final reader = ElectrumLineReader();
      const message = '{"id":"1","result":"deadbeef"}\n';
      final collected = <String>[];
      for (final byte in utf8.encode(message)) {
        collected.addAll(reader.feed([byte]));
      }
      expect(collected, ['{"id":"1","result":"deadbeef"}']);
    });

    // Regression test for the historical bug: the previous implementation
    // tried to `json.decode` each raw socket chunk independently before
    // falling back to buffering. A fragment landing on a run of digits
    // within a hex payload (e.g. "1234567890") parses as a *valid* bare
    // JSON number on its own, so the old code accepted it as a standalone
    // response and never appended its bytes to the reassembly buffer -
    // silently deleting that slice from the middle of the real message.
    test("does not drop a chunk that happens to be a bare JSON number", () {
      final reader = ElectrumLineReader();
      const message = '{"id":"1","result":"ab1234567890cd"}\n';
      final bytes = utf8.encode(message);
      // Split so that the middle chunk is exactly the digit run "1234567890",
      // which is a syntactically valid standalone JSON number.
      final digitsStart = message.indexOf("1234567890");
      final digitsEnd = digitsStart + "1234567890".length;

      final collected = <String>[
        ...reader.feed(bytes.sublist(0, digitsStart)),
        ...reader.feed(bytes.sublist(digitsStart, digitsEnd)),
        ...reader.feed(bytes.sublist(digitsEnd)),
      ];

      expect(collected, [message.substring(0, message.length - 1)]);
    });

    test("reset() discards any buffered partial line", () {
      final reader = ElectrumLineReader();
      reader.feed(utf8.encode('{"id":"1"'));
      reader.reset();
      expect(reader.feed(utf8.encode('{"id":"2"}\n')), ['{"id":"2"}']);
    });

    test(
        "never splits a multi-byte UTF-8 codepoint even when the chunk "
        "boundary lands mid-character", () {
      final reader = ElectrumLineReader();
      // "café" - the "é" is a 2-byte UTF-8 sequence.
      final prefix = utf8.encode('{"note":"caf');
      final eBytes = utf8.encode('é'); // 2-byte UTF-8 sequence: 0xC3 0xA9
      final suffix = utf8.encode('"}\n');
      expect(eBytes.length, 2);

      final firstChunk = [...prefix, eBytes[0]];
      final secondChunk = [eBytes[1], ...suffix];

      final collected = <String>[
        ...reader.feed(firstChunk),
        ...reader.feed(secondChunk),
      ];

      expect(collected, ['{"note":"café"}']);
    });

    for (final fixture in [
      "large_tx_260in_340out.hex",
      "large_tx_365in_454out.hex",
    ]) {
      test(
          "reassembles a large real transaction hex ($fixture) with no "
          "byte loss, split at every fixed chunk size from 1 to 4096", () {
        final hex = _readFixtureHex(fixture);
        final line = _rpcLine(hex);
        final bytes = utf8.encode(line);

        // try every chunk size to make sure the reader reassembles lines regardless of how input is fed
        for (final chunkSize in [1, 2, 3, 7, 13, 64, 512, 1024, 4096]) {
          final reader = ElectrumLineReader();
          // lines decoded so far across all chunks fed to `reader`
          final collected = <String>[];
          // walk through `bytes` in chunkSize-sized steps
          for (var offset = 0; offset < bytes.length; offset += chunkSize) {
            // clamp so the last chunk doesn't overrun `bytes`
            final end = min(offset + chunkSize, bytes.length);
            collected.addAll(reader.feed(bytes.sublist(offset, end)));
          }

          expect(collected.length, 1, reason: "chunkSize=$chunkSize");
          final decoded = json.decode(collected.first) as Map<String, dynamic>;
          expect(decoded["result"], hex, reason: "chunkSize=$chunkSize");
        }
      });

      test(
          "reassembles a large real transaction hex ($fixture) with no "
          "byte loss under randomized chunk sizes", () {
        final hex = _readFixtureHex(fixture);
        final line = _rpcLine(hex);
        final bytes = utf8.encode(line);
        final random = Random(1234);

        for (var trial = 0; trial < 20; trial++) {
          final chunkSizes = List.generate(50, (_) => 1 + random.nextInt(2000));
          final chunks = _splitBytes(bytes, chunkSizes);

          final reader = ElectrumLineReader();
          final collected = <String>[];
          for (final chunk in chunks) {
            collected.addAll(reader.feed(chunk));
          }

          expect(collected.length, 1, reason: "trial=$trial");
          final decoded = json.decode(collected.first) as Map<String, dynamic>;
          expect(decoded["result"], hex, reason: "trial=$trial");
        }
      });
    }
  });
}
