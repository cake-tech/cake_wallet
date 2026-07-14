// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mweb_utxo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MwebUtxoAdapter extends TypeAdapter<MwebUtxo> {
  @override
  final int typeId = 20;

  @override
  MwebUtxo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MwebUtxo(
      height: fields[0] as int,
      value: fields[1] as int,
      address: fields[2] as String,
      outputId: fields[3] as String,
      blockTime: fields[4] as int,
      spent: fields[5] == null ? false : fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MwebUtxo obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.height)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.outputId)
      ..writeByte(4)
      ..write(obj.blockTime)
      ..writeByte(5)
      ..write(obj.spent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MwebUtxoAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
