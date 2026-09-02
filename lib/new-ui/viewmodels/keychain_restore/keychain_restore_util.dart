import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/bitcoin_cash/bitcoin_cash.dart";
import "package:cake_wallet/core/generate_wallet_password.dart";
import "package:cake_wallet/decred/decred.dart";
import "package:cake_wallet/dogecoin/dogecoin.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/nano/nano.dart";
import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cake_wallet/zano/zano.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cw_core/pathForWallet.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_credentials.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:cw_keychain/cw_keychain.dart";
import "package:cw_zcash/cw_zcash.dart";

class KeychainRestoreUtilities {
  static Future<WalletCredentials> credentialsFromKeychainData(KeychainDataV1 data) async {
    final type = deserializeFromInt(data.walletTypeRaw);
    final password = generateWalletPassword();
    final WalletCredentials credentials;
    switch (type) {
      case WalletType.monero:
        credentials = monero!.createMoneroRestoreWalletFromSeedCredentials(
            name: data.name,
            height: data.blockHeight ?? 0,
            mnemonic: data.seed,
            password: password,
            passphrase: data.passphrase ?? "");
      case WalletType.bitcoin:
      case WalletType.litecoin:
        credentials = bitcoin!.createBitcoinRestoreWalletFromSeedCredentials(
          name: data.name,
          mnemonic: data.seed,
          password: password,
          passphrase: data.passphrase,
          derivationType: DerivationType.values[data.derivationTypeRaw],
          derivationPath: data.derivationPath!,
        );

      case WalletType.bitcoinCash:
        credentials = bitcoinCash!.createBitcoinCashRestoreWalletFromSeedCredentials(
          name: data.name,
          mnemonic: data.seed,
          password: password,
          passphrase: data.passphrase,
        );
      case WalletType.dogecoin:
        credentials = dogecoin!.createDogeCoinRestoreWalletFromSeedCredentials(
          name: data.name,
          mnemonic: data.seed,
          password: password,
          passphrase: data.passphrase,
        );
      case WalletType.nano:
        credentials = nano!.createNanoRestoreWalletFromSeedCredentials(
          name: data.name,
          mnemonic: data.seed,
          password: password,
          derivationType: DerivationType.values[data.derivationTypeRaw],
          passphrase: data.passphrase,
        );
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
        credentials = evm!.createEVMRestoreWalletFromSeedCredentials(
          name: data.name,
          mnemonic: data.seed,
          password: password,
          passphrase: data.passphrase,
        );
      case WalletType.solana:
        credentials = solana!.createSolanaRestoreWalletFromSeedCredentials(
          name: data.name,
          mnemonic: data.seed,
          password: password,
          passphrase: data.passphrase,
        );
      case WalletType.tron:
        credentials = tron!.createTronRestoreWalletFromSeedCredentials(
          name: data.name,
          mnemonic: data.seed,
          password: password,
          passphrase: data.passphrase,
        );
      case WalletType.zano:
        credentials = zano!.createZanoRestoreWalletFromSeedCredentials(
          name: data.name,
          password: password,
          height: data.blockHeight??0,
          passphrase: data.passphrase ?? "",
          mnemonic: data.seed,
        );
      case WalletType.decred:
        credentials = decred!.createDecredRestoreWalletFromSeedCredentials(
          name: data.name,
          mnemonic: data.seed,
          password: password,
        );
      case WalletType.zcash:
        credentials = zcash!.createZcashRestoreWalletFromSeedCredentials(
          name: data.name,
          mnemonic: data.seed,
          password: password,
          passphrase: data.passphrase,
          height: data.blockHeight,
          network: ZcashNetwork.mainnet.networkIndex,
        );
      case WalletType.none:
      case WalletType.haven:
      case WalletType.wownero:
      case WalletType.banano:
        throw Exception("bad wallet type for credential generation");
    }

    final dirPath = await pathForWalletDir(name: data.name, type: type);
    final path = await pathForWallet(name: data.name, type: type);

    credentials.derivationInfo ??= DerivationInfo(derivationType: DerivationType.unknown);
    final diId = await credentials.derivationInfo!.save();
    credentials.walletInfo = WalletInfo.external(
      id: WalletBase.idFor(data.name, type),
      name: data.name,
      type: type,
      isRecovery: false,
      restoreHeight: credentials.height ?? 0,
      date: DateTime.now(),
      path: path,
      dirPath: dirPath,
      address: "",
      showIntroCakePayCard: false,
      derivationInfoId: diId,
      hardwareWalletType: credentials.hardwareWalletType,
    );

    return credentials;
  }

}