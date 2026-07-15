// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tron_token.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TronTokenAdapter extends TypeAdapter<TronToken> {
  @override
  final int typeId = 18;

  @override
  TronToken read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TronToken(
      name: fields[0] as String,
      symbol: fields[1] as String,
      contractAddress: fields[2] as String,
      decimal: fields[3] as int,
      iconPath: fields[5] as String?,
      tag: fields[6] as String?,
      isPotentialScam: fields[7] == null ? false : fields[7] as bool,
    ).._enabled = fields[4] == null ? true : fields[4] as bool;
  }

  @override
  void write(BinaryWriter writer, TronToken obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.symbol)
      ..writeByte(2)
      ..write(obj.contractAddress)
      ..writeByte(3)
      ..write(obj.decimal)
      ..writeByte(4)
      ..write(obj._enabled)
      ..writeByte(5)
      ..write(obj.iconPath)
      ..writeByte(6)
      ..write(obj.tag)
      ..writeByte(7)
      ..write(obj.isPotentialScam);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TronTokenAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
