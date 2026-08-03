// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContactAdapter extends TypeAdapter<Contact> {
  @override
  final int typeId = 0;

  @override
  Contact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Contact(
      name: fields[0] == null ? '' : fields[0] as String,
      address: fields[1] == null ? '' : fields[1] as String,
      lastChange: fields[3] as DateTime?,
      displayName: fields[4] == null ? '' : fields[4] as String,
    )..raw = fields[2] == null ? 0 : fields[2] as int;
  }

  @override
  void write(BinaryWriter writer, Contact obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.raw)
      ..writeByte(3)
      ..write(obj.lastChange)
      ..writeByte(4)
      ..write(obj.displayName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
