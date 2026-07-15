// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'haven_seed_store.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HavenSeedStoreAdapter extends TypeAdapter<HavenSeedStore> {
  @override
  final int typeId = 21;

  @override
  HavenSeedStore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HavenSeedStore(
      id: fields[0] == null ? '' : fields[0] as String,
      seed: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HavenSeedStore obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.seed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HavenSeedStoreAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
