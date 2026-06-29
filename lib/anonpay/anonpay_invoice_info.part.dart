// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anonpay_invoice_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnonpayInvoiceInfoAdapter extends TypeAdapter<AnonpayInvoiceInfo> {
  @override
  final int typeId = 10;

  @override
  AnonpayInvoiceInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnonpayInvoiceInfo(
      invoiceId: fields[0] as String,
      clearnetUrl: fields[7] as String,
      onionUrl: fields[8] as String,
      clearnetStatusUrl: fields[9] as String,
      onionStatusUrl: fields[10] as String,
      status: fields[1] as String,
      fiatAmount: fields[2] as double?,
      fiatEquiv: fields[3] as String?,
      amountTo: fields[4] as double?,
      coinTo: fields[5] as String,
      address: fields[6] as String,
      createdAt: fields[11] as DateTime,
      walletId: fields[12] as String,
      provider: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AnonpayInvoiceInfo obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.invoiceId)
      ..writeByte(1)
      ..write(obj.status)
      ..writeByte(2)
      ..write(obj.fiatAmount)
      ..writeByte(3)
      ..write(obj.fiatEquiv)
      ..writeByte(4)
      ..write(obj.amountTo)
      ..writeByte(5)
      ..write(obj.coinTo)
      ..writeByte(6)
      ..write(obj.address)
      ..writeByte(7)
      ..write(obj.clearnetUrl)
      ..writeByte(8)
      ..write(obj.onionUrl)
      ..writeByte(9)
      ..write(obj.clearnetStatusUrl)
      ..writeByte(10)
      ..write(obj.onionStatusUrl)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.walletId)
      ..writeByte(13)
      ..write(obj.provider);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnonpayInvoiceInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
