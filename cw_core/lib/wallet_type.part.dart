// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WalletTypeAdapter extends TypeAdapter<WalletType> {
  @override
  final int typeId = 5;

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
        return WalletType.ethereum;
      case 6:
        return WalletType.nano;
      case 7:
        return WalletType.banano;
      case 8:
        return WalletType.bitcoinCash;
      case 9:
        return WalletType.polygon;
      case 10:
        return WalletType.solana;
      case 11:
        return WalletType.tron;
      case 12:
        return WalletType.wownero;
      case 13:
        return WalletType.zano;
      case 14:
        return WalletType.decred;
      case 15:
        return WalletType.dogecoin;
      case 16:
        return WalletType.base;
      case 17:
        return WalletType.arbitrum;
      case 18:
        return WalletType.zcash;
      case 19:
        return WalletType.bsc;
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
      case WalletType.ethereum:
        writer.writeByte(5);
        break;
      case WalletType.nano:
        writer.writeByte(6);
        break;
      case WalletType.banano:
        writer.writeByte(7);
        break;
      case WalletType.bitcoinCash:
        writer.writeByte(8);
        break;
      case WalletType.polygon:
        writer.writeByte(9);
        break;
      case WalletType.solana:
        writer.writeByte(10);
        break;
      case WalletType.tron:
        writer.writeByte(11);
        break;
      case WalletType.wownero:
        writer.writeByte(12);
        break;
      case WalletType.zano:
        writer.writeByte(13);
        break;
      case WalletType.decred:
        writer.writeByte(14);
        break;
      case WalletType.dogecoin:
        writer.writeByte(15);
        break;
      case WalletType.base:
        writer.writeByte(16);
        break;
      case WalletType.arbitrum:
        writer.writeByte(17);
        break;
      case WalletType.zcash:
        writer.writeByte(18);
        break;
      case WalletType.bsc:
        writer.writeByte(19);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletTypeAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
