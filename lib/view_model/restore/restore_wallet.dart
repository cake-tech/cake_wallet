import 'package:cw_core/wallet_type.dart';

class RestoredWallet {
  RestoredWallet(
      {required this.type,
      required this.address,
      this.spendKey,
      this.viewKey,
      this.mnemonicSeed,
      this.height});

  final WalletType type;
  final String address;
  final String? spendKey;
  final String? viewKey;
  final String? mnemonicSeed;
  final int? height;

  factory RestoredWallet.fromJson(Map<String, dynamic> json) {
    return RestoredWallet(
      type: json['type'] as WalletType,
      address: json['address'] as String,
      spendKey: json['spend_key'] as String?,
      viewKey: json['view_key'] as String?,
      mnemonicSeed: json['mnemonic_seed'] as String?,
      height: json['height'] as int?,
    );
  }
}
