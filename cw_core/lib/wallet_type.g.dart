// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WalletTypeAdapter extends TypeAdapter<WalletType> {
  @override
  final int typeId = 15;

  @override
  WalletType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WalletType.monero;
      case 1:
        return WalletType.none;
      case 2:
        return WalletType.bitcoin;
      case 3:
        return WalletType.litecoin;
      case 4:
        return WalletType.haven;
      case 5:
        return WalletType.wownero;
      default:
        return WalletType.monero;
    }
  }

  @override
  void write(BinaryWriter writer, WalletType obj) {
    switch (obj) {
      case WalletType.monero:
        writer.writeByte(0);
        break;
      case WalletType.none:
        writer.writeByte(1);
        break;
      case WalletType.bitcoin:
        writer.writeByte(2);
        break;
      case WalletType.litecoin:
        writer.writeByte(3);
        break;
      case WalletType.haven:
        writer.writeByte(4);
        break;
      case WalletType.wownero:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
