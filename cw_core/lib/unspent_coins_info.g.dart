// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unspent_coins_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UnspentCoinsInfoAdapter extends TypeAdapter<UnspentCoinsInfo> {
  @override
  final int typeId = 19;

  @override
  UnspentCoinsInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnspentCoinsInfo(
      walletId: fields[0] as String?,
      hash: fields[1] as String?,
      isFrozen: fields[2] as bool?,
      isSending: fields[3] as bool?,
      note: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UnspentCoinsInfo obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.walletId)
      ..writeByte(1)
      ..write(obj.hash)
      ..writeByte(2)
      ..write(obj.isFrozen)
      ..writeByte(3)
      ..write(obj.isSending)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnspentCoinsInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
