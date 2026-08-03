// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TemplateAdapter extends TypeAdapter<Template> {
  @override
  final int typeId = 6;

  @override
  Template read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Template(
      nameRaw: fields[0] as String?,
      isCurrencySelectedRaw: fields[5] as bool?,
      addressRaw: fields[1] as String?,
      cryptoCurrencyRaw: fields[2] as String?,
      amountRaw: fields[3] as String?,
      fiatCurrencyRaw: fields[4] as String?,
      amountFiatRaw: fields[6] as String?,
      additionalRecipientsRaw: (fields[7] as List?)?.cast<Template>(),
    );
  }

  @override
  void write(BinaryWriter writer, Template obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.nameRaw)
      ..writeByte(1)
      ..write(obj.addressRaw)
      ..writeByte(2)
      ..write(obj.cryptoCurrencyRaw)
      ..writeByte(3)
      ..write(obj.amountRaw)
      ..writeByte(4)
      ..write(obj.fiatCurrencyRaw)
      ..writeByte(5)
      ..write(obj.isCurrencySelectedRaw)
      ..writeByte(6)
      ..write(obj.amountFiatRaw)
      ..writeByte(7)
      ..write(obj.additionalRecipientsRaw);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
