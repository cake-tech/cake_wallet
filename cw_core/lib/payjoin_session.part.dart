// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payjoin_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PayjoinSessionAdapter extends TypeAdapter<PayjoinSession> {
  @override
  final int typeId = 23;

  @override
  PayjoinSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PayjoinSession(
      walletId: fields[0] as String,
      receiver: fields[2] as String?,
      sender: fields[1] as String?,
      pjUri: fields[3] as String?,
      status: fields[4] as String,
      inProgressSince: fields[5] as DateTime?,
      rawAmount: fields[7] as String?,
    )
      ..txId = fields[6] as String?
      ..error = fields[8] as String?;
  }

  @override
  void write(BinaryWriter writer, PayjoinSession obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.walletId)
      ..writeByte(1)
      ..write(obj.sender)
      ..writeByte(2)
      ..write(obj.receiver)
      ..writeByte(3)
      ..write(obj.pjUri)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.inProgressSince)
      ..writeByte(6)
      ..write(obj.txId)
      ..writeByte(7)
      ..write(obj.rawAmount)
      ..writeByte(8)
      ..write(obj.error);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayjoinSessionAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
