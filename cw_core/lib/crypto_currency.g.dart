// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crypto_currency.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CryptoCurrencyAdapter extends TypeAdapter<CryptoCurrency> {
  @override
  final int typeId = 10;

  @override
  CryptoCurrency read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CryptoCurrency();
  }

  @override
  void write(BinaryWriter writer, CryptoCurrency obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CryptoCurrencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
