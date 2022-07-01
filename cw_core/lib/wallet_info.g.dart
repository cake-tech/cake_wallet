// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WalletInfoAdapter extends TypeAdapter<WalletInfo> {
  @override
  final int typeId = 14;

  @override
  WalletInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WalletInfo(
      fields[0] as String?,
      fields[1] as String?,
      fields[2] as WalletType?,
      fields[3] as bool?,
      fields[4] as int?,
      fields[5] as int?,
      fields[6] as String?,
      fields[7] as String?,
      fields[8] as String?,
      fields[11] as String?,
      fields[12] as String?,
    )..addresses = (fields[10] as Map?)?.cast<String, String>();
  }

  @override
  void write(BinaryWriter writer, WalletInfo obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.isRecovery)
      ..writeByte(4)
      ..write(obj.restoreHeight)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.dirPath)
      ..writeByte(7)
      ..write(obj.path)
      ..writeByte(8)
      ..write(obj.address)
      ..writeByte(10)
      ..write(obj.addresses)
      ..writeByte(11)
      ..write(obj.yatEid)
      ..writeByte(12)
      ..write(obj.yatLastUsedAddressRaw);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
