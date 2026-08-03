// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_legacy.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NodeAdapter extends TypeAdapter<Node> {
  @override
  final int typeId = 1;

  @override
  Node read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Node(
      label: fields[12] == null ? '' : fields[12] as String?,
      login: fields[1] as String?,
      password: fields[2] as String?,
      useSSL: fields[4] as bool?,
      trusted: fields[5] == null ? false : fields[5] as bool,
      socksProxyAddress: fields[6] as String?,
      path: fields[7] == null ? '' : fields[7] as String?,
      isEnabledForAutoSwitching: fields[11] == null ? false : fields[11] as bool,
    )
      ..uriRaw = fields[0] == null ? '' : fields[0] as String
      ..typeRaw = fields[3] == null ? 0 : fields[3] as int
      ..isElectrs = fields[8] as bool?
      ..supportsSilentPayments = fields[9] as bool?
      ..supportsMweb = fields[10] as bool?;
  }

  @override
  void write(BinaryWriter writer, Node obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.uriRaw)
      ..writeByte(1)
      ..write(obj.login)
      ..writeByte(2)
      ..write(obj.password)
      ..writeByte(3)
      ..write(obj.typeRaw)
      ..writeByte(4)
      ..write(obj.useSSL)
      ..writeByte(5)
      ..write(obj.trusted)
      ..writeByte(6)
      ..write(obj.socksProxyAddress)
      ..writeByte(7)
      ..write(obj.path)
      ..writeByte(8)
      ..write(obj.isElectrs)
      ..writeByte(9)
      ..write(obj.supportsSilentPayments)
      ..writeByte(10)
      ..write(obj.supportsMweb)
      ..writeByte(11)
      ..write(obj.isEnabledForAutoSwitching)
      ..writeByte(12)
      ..write(obj.label);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
