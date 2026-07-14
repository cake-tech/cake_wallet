// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exchange_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExchangeTemplateAdapter extends TypeAdapter<ExchangeTemplate> {
  @override
  final int typeId = 7;

  @override
  ExchangeTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExchangeTemplate(
      amountRaw: fields[0] as String?,
      depositCurrencyRaw: fields[1] as String?,
      receiveCurrencyRaw: fields[2] as String?,
      providerRaw: fields[3] as String?,
      depositAddressRaw: fields[4] as String?,
      receiveAddressRaw: fields[5] as String?,
      depositCurrencyTitleRaw: fields[6] as String?,
      receiveCurrencyTitleRaw: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExchangeTemplate obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.amountRaw)
      ..writeByte(1)
      ..write(obj.depositCurrencyRaw)
      ..writeByte(2)
      ..write(obj.receiveCurrencyRaw)
      ..writeByte(3)
      ..write(obj.providerRaw)
      ..writeByte(4)
      ..write(obj.depositAddressRaw)
      ..writeByte(5)
      ..write(obj.receiveAddressRaw)
      ..writeByte(6)
      ..write(obj.depositCurrencyTitleRaw)
      ..writeByte(7)
      ..write(obj.receiveCurrencyTitleRaw);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
