// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderAdapter extends TypeAdapter<Order> {
  @override
  final int typeId = 8;

  @override
  Order read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Order(
      id: fields[0] == null ? '' : fields[0] as String,
      transferId: fields[1] == null ? '' : fields[1] as String,
      createdAt: fields[5] as DateTime,
      amount: fields[6] == null ? '' : fields[6] as String,
      receiveAmount: fields[10] == null ? '' : fields[10] as String?,
      quantity: fields[12] == null ? '' : fields[12] as String?,
      receiveAddress: fields[7] == null ? '' : fields[7] as String,
      walletId: fields[8] == null ? '' : fields[8] as String,
      from: fields[2] as String?,
      to: fields[3] as String?,
    )
      ..stateRaw = fields[4] == null ? '' : fields[4] as String
      ..providerRaw = fields[9] == null ? 0 : fields[9] as int
      ..sourceRaw = fields[11] == null ? 0 : fields[11] as int?;
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.transferId)
      ..writeByte(2)
      ..write(obj.from)
      ..writeByte(3)
      ..write(obj.to)
      ..writeByte(4)
      ..write(obj.stateRaw)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.amount)
      ..writeByte(7)
      ..write(obj.receiveAddress)
      ..writeByte(8)
      ..write(obj.walletId)
      ..writeByte(9)
      ..write(obj.providerRaw)
      ..writeByte(10)
      ..write(obj.receiveAmount)
      ..writeByte(11)
      ..write(obj.sourceRaw)
      ..writeByte(12)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
