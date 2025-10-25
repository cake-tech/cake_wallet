// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_info_legacy.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DerivationInfoAdapter extends TypeAdapter<DerivationInfo> {
  @override
  final int typeId = 17;

  @override
  DerivationInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DerivationInfo(
      derivationType: fields[3] as newWi.DerivationType?,
      derivationPath: fields[4] as String?,
      balance: fields[1] == null ? '' : fields[1] as String,
      address: fields[0] == null ? '' : fields[0] as String,
      transactionsCount: fields[2] == null ? 0 : fields[2] as int,
      scriptType: fields[5] as String?,
      description: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DerivationInfo obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.address)
      ..writeByte(1)
      ..write(obj.balance)
      ..writeByte(2)
      ..write(obj.transactionsCount)
      ..writeByte(3)
      ..write(obj.derivationType)
      ..writeByte(4)
      ..write(obj.derivationPath)
      ..writeByte(5)
      ..write(obj.scriptType)
      ..writeByte(6)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DerivationInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WalletInfoAdapter extends TypeAdapter<WalletInfo> {
  @override
  final int typeId = 4;

  @override
  WalletInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WalletInfo(
      fields[0] == null ? '' : fields[0] as String,
      fields[1] == null ? '' : fields[1] as String,
      fields[2] as WalletType,
      fields[3] == null ? false : fields[3] as bool,
      fields[4] == null ? 0 : fields[4] as int,
      fields[5] == null ? 0 : fields[5] as int,
      fields[6] == null ? '' : fields[6] as String,
      fields[7] == null ? '' : fields[7] as String,
      fields[8] == null ? '' : fields[8] as String,
      fields[11] as String?,
      fields[12] as String?,
      fields[13] as bool?,
      fields[20] as DerivationInfo?,
      fields[21] as newWi.HardwareWalletType?,
      fields[22] as String?,
      fields[25] as String?,
      fields[26] == null ? false : fields[26] as bool,
    )
      ..addresses = (fields[10] as Map?)?.cast<String, String>()
      ..addressInfos = (fields[14] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as int, (v as List).cast<AddressInfo>()))
      ..usedAddresses = (fields[15] as List?)?.cast<String>()
      ..derivationType = fields[16] as newWi.DerivationType?
      ..derivationPath = fields[17] as String?
      ..addressPageType = fields[18] as String?
      ..network = fields[19] as String?
      ..hiddenAddresses = (fields[23] as List?)?.cast<String>()
      ..manualAddresses = (fields[24] as List?)?.cast<String>();
  }

  @override
  void write(BinaryWriter writer, WalletInfo obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.isRecovery)
      ..writeByte(4)
      ..write(obj.restoreHeight)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.dirPath)
      ..writeByte(7)
      ..write(obj.path)
      ..writeByte(8)
      ..write(obj.address)
      ..writeByte(10)
      ..write(obj.addresses)
      ..writeByte(11)
      ..write(obj.yatEid)
      ..writeByte(12)
      ..write(obj.yatLastUsedAddressRaw)
      ..writeByte(13)
      ..write(obj.showIntroCakePayCard)
      ..writeByte(14)
      ..write(obj.addressInfos)
      ..writeByte(15)
      ..write(obj.usedAddresses)
      ..writeByte(16)
      ..write(obj.derivationType)
      ..writeByte(17)
      ..write(obj.derivationPath)
      ..writeByte(18)
      ..write(obj.addressPageType)
      ..writeByte(19)
      ..write(obj.network)
      ..writeByte(20)
      ..write(obj.derivationInfo)
      ..writeByte(21)
      ..write(obj.hardwareWalletType)
      ..writeByte(22)
      ..write(obj.parentAddress)
      ..writeByte(23)
      ..write(obj.hiddenAddresses)
      ..writeByte(24)
      ..write(obj.manualAddresses)
      ..writeByte(25)
      ..write(obj.hashedWalletIdentifier)
      ..writeByte(26)
      ..write(obj.isNonSeedWallet);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DerivationTypeAdapter extends TypeAdapter<newWi.DerivationType> {
  @override
  final int typeId = 15;

  @override
  newWi.DerivationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return newWi.DerivationType.unknown;
      case 1:
        return newWi.DerivationType.def;
      case 2:
        return newWi.DerivationType.nano;
      case 3:
        return newWi.DerivationType.bip39;
      case 4:
        return newWi.DerivationType.electrum;
      default:
        return newWi.DerivationType.unknown;
    }
  }

  @override
  void write(BinaryWriter writer, newWi.DerivationType obj) {
    switch (obj) {
      case newWi.DerivationType.unknown:
        writer.writeByte(0);
        break;
      case newWi.DerivationType.def:
        writer.writeByte(1);
        break;
      case newWi.DerivationType.nano:
        writer.writeByte(2);
        break;
      case newWi.DerivationType.bip39:
        writer.writeByte(3);
        break;
      case newWi.DerivationType.electrum:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DerivationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HardwareWalletTypeAdapter extends TypeAdapter<newWi.HardwareWalletType> {
  @override
  final int typeId = 19;

  @override
  newWi.HardwareWalletType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return newWi.HardwareWalletType.ledger;
      case 1:
        return newWi.HardwareWalletType.bitbox;
      case 2:
        return newWi.HardwareWalletType.cupcake;
      case 3:
        return newWi.HardwareWalletType.coldcard;
      case 4:
        return newWi.HardwareWalletType.seedsigner;
      case 5:
        return newWi.HardwareWalletType.keystone;
      case 6:
        return newWi.HardwareWalletType.trezor;
      default:
        return newWi.HardwareWalletType.ledger;
    }
  }

  @override
  void write(BinaryWriter writer, newWi.HardwareWalletType obj) {
    switch (obj) {
      case newWi.HardwareWalletType.ledger:
        writer.writeByte(0);
        break;
      case newWi.HardwareWalletType.bitbox:
        writer.writeByte(1);
        break;
      case newWi.HardwareWalletType.cupcake:
        writer.writeByte(2);
        break;
      case newWi.HardwareWalletType.coldcard:
        writer.writeByte(3);
        break;
      case newWi.HardwareWalletType.seedsigner:
        writer.writeByte(4);
        break;
      case newWi.HardwareWalletType.keystone:
        writer.writeByte(5);
        break;
      case newWi.HardwareWalletType.trezor:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HardwareWalletTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
