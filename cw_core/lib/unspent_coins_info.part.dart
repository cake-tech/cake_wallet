// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unspent_coins_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UnspentCoinsInfoAdapter extends TypeAdapter<UnspentCoinsInfo> {
  @override
  final int typeId = 9;

  @override
  UnspentCoinsInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnspentCoinsInfo(
      walletId: fields[0] == null ? '' : fields[0] as String,
      hash: fields[1] == null ? '' : fields[1] as String,
      isFrozen: fields[2] == null ? false : fields[2] as bool,
      isSending: fields[3] == null ? false : fields[3] as bool,
      noteRaw: fields[4] as String?,
      address: fields[5] == null ? '' : fields[5] as String,
      vout: fields[7] == null ? 0 : fields[7] as int,
      value: fields[6] == null ? 0 : fields[6] as int,
      keyImage: fields[8] as String?,
      isChange: fields[9] == null ? false : fields[9] as bool,
      accountIndex: fields[10] == null ? 0 : fields[10] as int,
      isSilentPayment: fields[11] == null ? false : fields[11] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, UnspentCoinsInfo obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.walletId)
      ..writeByte(1)
      ..write(obj.hash)
      ..writeByte(2)
      ..write(obj.isFrozen)
      ..writeByte(3)
      ..write(obj.isSending)
      ..writeByte(4)
      ..write(obj.noteRaw)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.value)
      ..writeByte(7)
      ..write(obj.vout)
      ..writeByte(8)
      ..write(obj.keyImage)
      ..writeByte(9)
      ..write(obj.isChange)
      ..writeByte(10)
      ..write(obj.accountIndex)
      ..writeByte(11)
      ..write(obj.isSilentPayment);
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
