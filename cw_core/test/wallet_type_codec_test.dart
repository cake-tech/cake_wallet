import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";

class _FakeBinaryReader extends Fake implements BinaryReader {
  _FakeBinaryReader(this.byte);

  final int byte;

  @override
  int readByte() => byte;
}

class _FakeBinaryWriter extends Fake implements BinaryWriter {
  final List<int> written = [];

  @override
  void writeByte(int byte) => written.add(byte);
}

void main() {
  group("WalletType codecs", () {
    test("every wallet type round-trips through serializeToInt", () {
      for (final type in WalletType.values.where((type) => type != WalletType.none)) {
        expect(deserializeFromInt(serializeToInt(type)), type, reason: "$type");
      }
    });

    test("evm is appended after robinhood in every codec", () {
      expect(serializeToInt(WalletType.robinhood), 19);
      expect(serializeToInt(WalletType.evm), 20);
      expect(WalletType.values.indexOf(WalletType.robinhood), 20);
      expect(WalletType.values.indexOf(WalletType.evm), 21);
    });

    test("the Hive adapter reads and writes evm as byte 21", () {
      final adapter = WalletTypeAdapter();

      expect(adapter.read(_FakeBinaryReader(21)), WalletType.evm);
      expect(adapter.read(_FakeBinaryReader(20)), WalletType.robinhood);

      final writer = _FakeBinaryWriter();
      adapter.write(writer, WalletType.evm);
      adapter.write(writer, WalletType.robinhood);
      expect(writer.written, [21, 20]);
    });

    test("every wallet type round-trips through the Hive adapter", () {
      final adapter = WalletTypeAdapter();

      for (final type in WalletType.values) {
        final writer = _FakeBinaryWriter();
        adapter.write(writer, type);
        expect(adapter.read(_FakeBinaryReader(writer.written.single)), type, reason: "$type");
      }
    });
  });
}
