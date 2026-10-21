// Builders for hand-assembled ABI calldata used by the decoder tests.

String word(BigInt value) => value.toRadixString(16).padLeft(64, "0");

String wordInt(int value) => word(BigInt.from(value));

String wordAddr(String address) => address.toLowerCase().replaceFirst("0x", "").padLeft(64, "0");

String bytesBlob(String hexData) {
  final byteLength = hexData.length ~/ 2;
  final padded = hexData.padRight(((hexData.length + 63) ~/ 64) * 64, "0");
  return wordInt(byteLength) + padded;
}

String addressArrayBody(List<String> addresses) =>
    wordInt(addresses.length) + addresses.map(wordAddr).join();

String uintArrayBody(List<BigInt> values) => wordInt(values.length) + values.map(word).join();

String bytesArrayBody(List<String> elements) {
  final offsets = <int>[];
  var cursor = elements.length * 32;
  final blobs = <String>[];
  for (final element in elements) {
    offsets.add(cursor);
    final blob = bytesBlob(element);
    blobs.add(blob);
    cursor += blob.length ~/ 2;
  }
  return wordInt(elements.length) + offsets.map(wordInt).join() + blobs.join();
}

List<int> u32Le(int value) => [
      value & 0xff,
      (value >> 8) & 0xff,
      (value >> 16) & 0xff,
      (value >> 24) & 0xff,
    ];

List<int> u64Le(BigInt value) {
  final out = <int>[];
  var v = value;
  for (var i = 0; i < 8; i++) {
    out.add((v & BigInt.from(0xff)).toInt());
    v = v >> 8;
  }
  return out;
}
