import 'dart:convert';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/seedbyte_types.dart';
import 'package:cw_core/wallet_info.dart';

class BaseBitcoinAddressRecord {
  BaseBitcoinAddressRecord(
    this.address, {
    required this.index,
    bool isChange = false,
    int txCount = 0,
    ElectrumBalance? balance,
    String name = '',
    bool isUsed = false,
    required this.type,
    required this.network,
    this.seedBytesType,
    bool? isHidden,
    String? derivationPath,
  })  : _txCount = txCount,
        balance = balance ?? ElectrumBalance.zero(),
        _name = name,
        _isUsed = isUsed,
        isHidden = isHidden ?? isChange,
        _isChange = isChange,
        _derivationPath = derivationPath ?? '';

  @override
  bool operator ==(Object o) => o is BaseBitcoinAddressRecord && address == o.address;

  final String address;
  bool isHidden;

  final bool _isChange;

  bool get isChange => _isChange;
  final int index;
  int _txCount;
  ElectrumBalance balance;
  String _name;
  bool _isUsed;

  BasedUtxoNetwork network;

  int get txCount => _txCount;

  String get name => _name;

  set txCount(int value) => _txCount = value;

  bool get isUsed => _isUsed;

  void setAsUsed() {
    _isUsed = true;
    isHidden = true;
  }

  void setNewName(String label) => _name = label;

  int get hashCode => address.hashCode;

  BitcoinAddressType type;

  final SeedBytesType? seedBytesType;

  final String _derivationPath;

  String get indexedDerivationPath => _derivationPath;

  bool isUnusedReceiveAddress() {
    return !isChange && !getIsUsed();
  }

  bool getIsUsed() {
    return isUsed || txCount != 0 || balance.hasBalance();
  }

  // An address not yet used for receiving funds
  bool getIsStillReceiveable(bool autoGenerateAddresses) =>
      !autoGenerateAddresses || (!getIsUsed() && (isChange || !isHidden));

  String toJSON() => json.encode({
        'address': address,
        'network': network.value,
        'index': index,
        'isHidden': isHidden,
        'isChange': isChange,
        'isUsed': isUsed,
        'txCount': txCount,
        'name': name,
        'balance': balance.toJSON(),
        'type': type.toString(),
        'runtimeType': runtimeType.toString(),
        'seedBytesType': seedBytesType?.value,
        'derivationPath': indexedDerivationPath,
      });

  static BaseBitcoinAddressRecord buildFromJSON(
    String jsonSource, [
    DerivationInfo? derivationInfo,
  ]) {
    final decoded = json.decode(jsonSource) as Map;
    final seedBytesTypeSnp = decoded['seedBytesType'] as String?;
    final seedBytesType = seedBytesTypeSnp == null
        ? derivationInfo == null
            ? null
            : (derivationInfo.derivationType == DerivationType.bip39
                ? SeedBytesType.old_bip39
                : SeedBytesType.old_electrum)
        : SeedBytesType.fromValue(seedBytesTypeSnp.toString());

    final balance = decoded['balance'] is String
        ? ElectrumBalance.fromJSON(decoded['balance'] as String)
        : ElectrumBalance.zero();

    return BaseBitcoinAddressRecord(
      decoded['address'] as String,
      network: BasedUtxoNetwork.fromName(decoded['network'] as String),
      index: decoded['index'] as int,
      seedBytesType: seedBytesType,
      isHidden: decoded['isHidden'] as bool? ?? false,
      isChange: decoded['isChange'] as bool? ?? false,
      isUsed: decoded['isUsed'] as bool? ?? false,
      txCount: decoded['txCount'] as int? ?? 0,
      name: decoded['name'] as String? ?? '',
      balance: balance,
      derivationPath: decoded['derivationPath'] as String? ?? '',
      type: decoded['type'] != null && decoded['type'] != ''
          ? BitcoinAddressType.values
              .firstWhere((type) => type.toString() == decoded['type'] as String)
          : SegwitAddressType.p2wpkh,
    );
  }

  static BaseBitcoinAddressRecord fromJSON(
    String jsonSource, [
    DerivationInfo? derivationInfo,
  ]) {
    final decoded = json.decode(jsonSource) as Map;
    final base = buildFromJSON(jsonSource, derivationInfo);

    if (decoded['runtimeType'] == 'BitcoinAddressRecord') {
      return BitcoinAddressRecord.fromJSON(jsonSource, base, derivationInfo);
    } else if (decoded['runtimeType'] == 'BitcoinSilentPaymentAddressRecord') {
      return BitcoinSilentPaymentAddressRecord.fromJSON(jsonSource, base);
    } else if (decoded['runtimeType'] == 'BitcoinReceivedSPAddressRecord') {
      return BitcoinReceivedSPAddressRecord.fromJSON(jsonSource, base);
    } else if (decoded['runtimeType'] == 'LitecoinMWEBAddressRecord') {
      return LitecoinMWEBAddressRecord.fromJSON(jsonSource, base);
    } else {
      return BitcoinAddressRecord.fromJSON(jsonSource, base, derivationInfo);
    }
  }
}

class BitcoinAddressRecord extends BaseBitcoinAddressRecord {
  final BitcoinDerivationInfo derivationInfo;

  String _derivationPath = '';

  @override
  String get indexedDerivationPath => _derivationPath;

  BitcoinAddressRecord(
    super.address, {
    required super.index,
    required this.derivationInfo,
    required super.network,
    super.seedBytesType,
    super.isHidden,
    required super.isChange,
    super.txCount = 0,
    super.balance,
    super.name = '',
    super.isUsed = false,
    required super.type,
    String? scriptHash,
    String? derivationPath,
  }) {
    if (scriptHash != null) {
      this.scriptHash = scriptHash;
    } else {
      this.scriptHash = BitcoinAddressUtils.scriptHash(address, network: network);
    }

    _derivationPath = derivationPath ??
        derivationInfo.derivationPath
            .addElem(Bip32KeyIndex(isChange ? 1 : 0))
            .addElem(Bip32KeyIndex(index))
            .toString();

    if (getShouldHideAddressByDefault()) {
      isHidden = true;
    }
  }

  factory BitcoinAddressRecord.fromJSON(
    String jsonSource, [
    BaseBitcoinAddressRecord? base,
    DerivationInfo? derivationInfo,
  ]) {
    base ??= BaseBitcoinAddressRecord.buildFromJSON(jsonSource);
    final decoded = json.decode(jsonSource) as Map;
    final derivationInfoSnp = decoded['derivationInfo'] as Map<String, dynamic>?;
    final seedBytesType = base.seedBytesType;

    return BitcoinAddressRecord(
      base.address,
      network: base.network,
      index: base.index,
      seedBytesType: seedBytesType,
      isHidden: base.isHidden,
      isChange: base.isChange,
      isUsed: base.isUsed,
      txCount: base.txCount,
      name: base.name,
      balance: base.balance,
      type: base.type,
      derivationPath: base.indexedDerivationPath,
      scriptHash: decoded['scriptHash'] as String?,
      derivationInfo: derivationInfoSnp == null
          ? seedBytesType != null && !seedBytesType.isElectrum
              ? BitcoinDerivationInfo.fromDerivationAndAddress(
                  BitcoinDerivationType.bip39,
                  decoded['address'] as String,
                  base.network,
                )
              : BitcoinDerivationInfos.ELECTRUM
          : BitcoinDerivationInfo.fromJSON(derivationInfoSnp),
    );
  }

  late String scriptHash;

  // Manages the wrong derivation path addresses
  bool getShouldHideAddressByDefault() {
    final path = derivationInfo.derivationPath.toString();

    return path !=
        BitcoinAddressUtils.getDerivationFromType(
          type,
          network: network,
          isElectrum: seedBytesType!.isElectrum,
        ).derivationPath.toString();
  }

  @override
  String toJSON() {
    final m = json.decode(super.toJSON()) as Map<String, dynamic>;
    m['derivationInfo'] = derivationInfo.toJSON();
    m['scriptHash'] = scriptHash;
    return json.encode(m);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BitcoinAddressRecord &&
        other.address == address &&
        other.index == index &&
        other.derivationInfo == derivationInfo &&
        other.scriptHash == scriptHash &&
        other.type == type &&
        other.seedBytesType == seedBytesType;
  }

  @override
  int get hashCode =>
      address.hashCode ^
      index.hashCode ^
      derivationInfo.hashCode ^
      scriptHash.hashCode ^
      type.hashCode ^
      seedBytesType.hashCode;
}

class BitcoinSilentPaymentAddressRecord extends BaseBitcoinAddressRecord {
  static BitcoinDerivationInfo DEFAULT_DERIVATION_INFO =
      BitcoinDerivationInfos.SILENT_PAYMENTS_SPEND;
  static String DEFAULT_DERIVATION_PATH = DEFAULT_DERIVATION_INFO.derivationPath.toString();

  String _derivationPath;

  @override
  String get indexedDerivationPath => _derivationPath;

  int get labelIndex => index;
  final String? labelHex;

  bool get isPrimaryAddress => labelIndex == 0;

  BitcoinSilentPaymentAddressRecord(
    super.address, {
    required int labelIndex,
    required super.network,
    String? derivationPath,
    super.txCount = 0,
    super.balance,
    super.name = '',
    super.isUsed = false,
    super.type = SilentPaymentsAddresType.p2sp,
    required super.isChange,
    super.seedBytesType,
    super.isHidden,
    this.labelHex,
  })  : _derivationPath = derivationPath ?? DEFAULT_DERIVATION_PATH,
        super(index: labelIndex) {
    if (labelIndex != 0 && labelHex == null) {
      throw ArgumentError('label must be provided for silent address index != 1');
    }

    if (_derivationPath != DEFAULT_DERIVATION_PATH) {
      isHidden = true;
    }

    if (labelIndex != 0 && derivationPath == null) {
      _derivationPath = _derivationPath.replaceAll(RegExp(r'\d\/?$'), '$labelIndex');
    }
  }

  factory BitcoinSilentPaymentAddressRecord.fromJSON(
    String jsonSource, [
    BaseBitcoinAddressRecord? base,
  ]) {
    base ??= BaseBitcoinAddressRecord.buildFromJSON(jsonSource);
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinSilentPaymentAddressRecord(
      base.address,
      network: base.network,
      seedBytesType: base.seedBytesType,
      isHidden: base.isHidden,
      isChange: base.isChange,
      isUsed: base.isUsed,
      txCount: base.txCount,
      name: base.name,
      balance: base.balance,
      type: base.type,
      labelIndex: base.index,
      derivationPath: base.indexedDerivationPath,
      labelHex: decoded['labelHex'] as String?,
    );
  }

  @override
  String toJSON() {
    final m = json.decode(super.toJSON()) as Map<String, dynamic>;
    m['index'] = labelIndex;
    m['labelHex'] = labelHex;
    return json.encode(m);
  }
}

class BitcoinReceivedSPAddressRecord extends BitcoinSilentPaymentAddressRecord {
  final String tweak;
  final String spAddress;

  @override
  String get indexedDerivationPath => '';

  BitcoinReceivedSPAddressRecord(
    super.address, {
    required super.labelIndex,
    required super.network,
    super.txCount = 0,
    super.balance,
    super.name = '',
    super.isUsed = false,
    required this.tweak,
    required this.spAddress,
    required super.isChange,
    super.seedBytesType,
    super.labelHex,
  }) : super(isHidden: true, type: SegwitAddressType.p2tr);

  SilentPaymentOwner getSPWallet(
    List<SilentPaymentOwner> silentPaymentsWallets, [
    BasedUtxoNetwork network = BitcoinNetwork.mainnet,
  ]) {
    return silentPaymentsWallets.firstWhere(
      (wallet) => wallet.toAddress(network) == spAddress,
      orElse: () => throw ArgumentError('SP wallet not found'),
    );
  }

  ECPrivate getSpendKey(
    List<SilentPaymentOwner> silentPaymentsWallets, [
    BasedUtxoNetwork network = BitcoinNetwork.mainnet,
  ]) {
    return getSPWallet(silentPaymentsWallets, network)
        .b_spend
        .tweakAdd(BigintUtils.fromBytes(BytesUtils.fromHexString(tweak)));
  }

  factory BitcoinReceivedSPAddressRecord.fromJSON(
    String jsonSource, [
    BaseBitcoinAddressRecord? base,
  ]) {
    base ??= BaseBitcoinAddressRecord.buildFromJSON(jsonSource);
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinReceivedSPAddressRecord(
      base.address,
      network: base.network,
      seedBytesType: base.seedBytesType,
      isChange: base.isChange,
      isUsed: base.isUsed,
      txCount: base.txCount,
      name: base.name,
      balance: base.balance,
      labelIndex: base.index,
      labelHex: decoded['labelHex'] as String?,
      spAddress: decoded['spAddress'] as String? ?? '',
      tweak: decoded['tweak'] as String? ?? decoded['silent_payment_tweak'] as String? ?? '',
    );
  }

  @override
  String toJSON() {
    final m = json.decode(super.toJSON()) as Map<String, dynamic>;
    m['tweak'] = tweak;
    m['spAddress'] = spAddress;
    return json.encode(m);
  }
}

class LitecoinMWEBAddressRecord extends BaseBitcoinAddressRecord {
  String _derivationPath = '';

  @override
  String get indexedDerivationPath => _derivationPath;

  LitecoinMWEBAddressRecord(
    super.address, {
    required super.index,
    required super.network,
    super.seedBytesType,
    super.isHidden,
    super.isChange = false,
    super.txCount = 0,
    super.balance,
    super.name = '',
    super.isUsed = false,
  }) : super(type: SegwitAddressType.mweb) {
    var mwebPath = BitcoinDerivationInfos.LITECOIN_MWEB.derivationPath;

    _derivationPath = mwebPath.addElem(Bip32KeyIndex(index)).toString();
  }

  factory LitecoinMWEBAddressRecord.fromJSON(
    String jsonSource, [
    BaseBitcoinAddressRecord? base,
  ]) {
    base ??= BaseBitcoinAddressRecord.buildFromJSON(jsonSource);

    return LitecoinMWEBAddressRecord(
      base.address,
      network: base.network,
      index: base.index,
      seedBytesType: base.seedBytesType,
      isHidden: base.isHidden,
      isChange: base.isChange,
      isUsed: base.isUsed,
      txCount: base.txCount,
      name: base.name,
      balance: base.balance,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BitcoinAddressRecord &&
        other.address == address &&
        other.index == index &&
        other.type == type;
  }

  @override
  int get hashCode => address.hashCode ^ index.hashCode ^ type.hashCode;
}
