import 'package:cake_wallet/view_model/restore/restore_mode.dart';
import 'package:cw_core/wallet_type.dart';

class RestoredWallet {
  RestoredWallet(
      {required this.restoreMode,
      required this.type,
      required this.address,
      this.spendKey,
      this.viewKey,
      this.mnemonicSeed,
      this.height});

  final WalletRestoreMode restoreMode;
  final WalletType type;
  final String address;
  final String? spendKey;
  final String? viewKey;
  final String? mnemonicSeed;
  final int? height;

  factory RestoredWallet.fromJson(Map<String, dynamic> json) {
    final height = json['height'] as String?;
    return RestoredWallet(
      restoreMode: json['mode'] as WalletRestoreMode,
      type: json['type'] as WalletType,
      address: json['address'] as String,
      spendKey: json['spend_key'] as String?,
      viewKey: json['view_key'] as String?,
      mnemonicSeed: json['mnemonic_seed'] as String?,
      height: height != null ? int.parse(height) : 0,
    );
  }
}
