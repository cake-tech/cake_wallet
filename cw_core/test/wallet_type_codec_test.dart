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

    test("evm is appended after bsc in every codec", () {
      expect(serializeToInt(WalletType.bsc), 18);
      expect(serializeToInt(WalletType.evm), 19);
      expect(WalletType.values.indexOf(WalletType.bsc), 19);
      expect(WalletType.values.indexOf(WalletType.evm), 20);
    });

    test("the Hive adapter reads and writes evm as byte 20", () {
      final adapter = WalletTypeAdapter();

      expect(adapter.read(_FakeBinaryReader(20)), WalletType.evm);
      expect(adapter.read(_FakeBinaryReader(19)), WalletType.bsc);

      final writer = _FakeBinaryWriter();
      adapter.write(writer, WalletType.evm);
      adapter.write(writer, WalletType.bsc);
      expect(writer.written, [20, 19]);
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
