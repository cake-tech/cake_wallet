// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zano_asset.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ZanoAssetAdapter extends TypeAdapter<ZanoAsset> {
  @override
  final int typeId = 22;

  @override
  ZanoAsset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ZanoAsset(
      fullName: fields[0] as String,
      ticker: fields[1] as String,
      assetId: fields[2] as String,
      decimalPoint: fields[3] as int,
      iconPath: fields[5] as String?,
      owner: fields[6] as String,
      metaInfo: fields[7] as String,
      currentSupply: fields[8] as BigInt,
      hiddenSupply: fields[9] as bool,
      totalMaxSupply: fields[10] as BigInt,
      isInGlobalWhitelist: fields[11] as bool,
      info: (fields[12] as Map?)?.cast<String, dynamic>(),
    ).._enabled = fields[4] == null ? true : fields[4] as bool;
  }

  @override
  void write(BinaryWriter writer, ZanoAsset obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.fullName)
      ..writeByte(1)
      ..write(obj.ticker)
      ..writeByte(2)
      ..write(obj.assetId)
      ..writeByte(3)
      ..write(obj.decimalPoint)
      ..writeByte(4)
      ..write(obj._enabled)
      ..writeByte(5)
      ..write(obj.iconPath)
      ..writeByte(6)
      ..write(obj.owner)
      ..writeByte(7)
      ..write(obj.metaInfo)
      ..writeByte(8)
      ..write(obj.currentSupply)
      ..writeByte(9)
      ..write(obj.hiddenSupply)
      ..writeByte(10)
      ..write(obj.totalMaxSupply)
      ..writeByte(11)
      ..write(obj.isInGlobalWhitelist)
      ..writeByte(12)
      ..write(obj.info);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZanoAssetAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
