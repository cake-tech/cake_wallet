
import "package:cake_wallet/di.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:cw_keychain/cw_keychain.dart";

extension WalletBaseToKeychainData on WalletBase {
  KeychainDataV1 get keychainData => KeychainDataV1(
    name: name,
    walletTypeRaw: serializeToInt(type),
    // we only support mainnet and testnet right now
    networkRaw: isTestnet ? 1 : 0,
    // "1" is "default"
    derivationTypeRaw: derivationInfo.derivationType?.index ?? 1,
    derivationPath: derivationInfo.derivationPath,
    seed: seed!,
    passphrase: passphrase,
    seedTypeRaw: _seedTypeRaw,
    blockHeight: _restoreHeight,
    creationTime: DateTime.now().millisecondsSinceEpoch,
  );

  int? get _seedTypeRaw {
    // HACK: would prefer to do it without this getIt but wallets don't store this info
    final settingsStore = getIt.get<SettingsStore>();
    return switch (type) {
      WalletType.monero => settingsStore.moneroSeedType.raw,
      WalletType.bitcoin => settingsStore.bitcoinSeedType.raw,
      WalletType.nano => settingsStore.nanoSeedType.raw,
      _ => null
    };
  }

  int? get _restoreHeight {
    if (type == WalletType.monero) {
      return monero!.getRestoreHeight(this);
    }
    if (type == WalletType.zcash) {
      return int.tryParse(zcash!.getKeys(this)["restoreHeight"]?.toString() ?? "");
    }
    return null;
  }
}
