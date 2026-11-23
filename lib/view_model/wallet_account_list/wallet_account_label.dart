import "package:cake_wallet/generated/i18n.dart";
import "package:cw_core/wallet_account.dart";

extension WalletAccountLabel on WalletAccount {
  String get displayLabel =>
      label ?? (index == 0 ? "Primary account" : "${S.current.account} $index");
}