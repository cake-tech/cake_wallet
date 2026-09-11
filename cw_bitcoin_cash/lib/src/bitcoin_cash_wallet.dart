import "package:bitbox/bitbox.dart" as bitbox;
import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_mnemonics_bip39.dart";
import "package:cw_bitcoin/bitcoin_transaction_priority.dart";
import "package:cw_bitcoin/electrum_balance.dart";
import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_bitcoin/electrum_wallet_snapshot.dart";
import "package:cw_bitcoin_cash/src/bitcoin_cash_address_utils.dart";
import "package:cw_bitcoin_cash/src/bitcoin_cash_wallet_addresses.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/encryption_file_utils.dart";
import "package:cw_core/transaction_priority.dart";
import "package:cw_core/unspent_coins_info.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_keys_file.dart";
import "package:flutter/foundation.dart";
import "package:hive/hive.dart";
import "package:mobx/mobx.dart";

part "bitcoin_cash_wallet.g.dart";

class BitcoinCashWallet = BitcoinCashWalletBase with _$BitcoinCashWallet;

abstract class BitcoinCashWalletBase extends ElectrumWallet with Store {
  BitcoinCashWalletBase({
    required String super.mnemonic,
    required super.password,
    required WalletInfo walletInfo,
    required super.derivationInfo,
    required super.unspentCoinsInfo,
    required Uint8List super.seedBytes,
    required super.encryptionFileUtils,
    super.passphrase,
    super.initialBalance,
    BitcoinAddressType? addressPageType,
    List<BitcoinAddressRecord>? initialAddresses,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
  }) : super(
          walletInfo: walletInfo,
          network: BitcoinCashNetwork.mainnet,
          initialAddresses: initialAddresses,
          currency: CryptoCurrency.bch,
        ) {
    walletAddresses = BitcoinCashWalletAddresses(
      walletInfo,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      mainHdByType: mainHdByType,
      sideHdByType: sideHdByType,
      legacyMainHd: mainHd,
      legacySideHd: sideHd,
      network: network,
      initialAddressPageType: addressPageType,
      isHardwareWallet: walletInfo.isHardwareWallet,
    );
    autorun(
      (_) => walletAddresses.isEnabledAutoGenerateSubaddress = isEnabledAutoGenerateSubaddress,
    );
  }

  static Future<BitcoinCashWallet> create({
    required String mnemonic,
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required EncryptionFileUtils encryptionFileUtils,
    String? passphrase,
    String? addressPageType,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
  }) async => BitcoinCashWallet(
      mnemonic: mnemonic,
      password: password,
      walletInfo: walletInfo,
      derivationInfo: await walletInfo.getDerivationInfo(),
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: initialAddresses,
      initialBalance: initialBalance,
      seedBytes: MnemonicBip39.toSeed(mnemonic, passphrase: passphrase),
      encryptionFileUtils: encryptionFileUtils,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      addressPageType: P2pkhAddressType.p2pkh,
      passphrase: passphrase,
    );

  static Future<BitcoinCashWallet> open({
    required String name,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required String password,
    required EncryptionFileUtils encryptionFileUtils,
  }) async {
    final hasKeysFile = await WalletKeysFile.hasKeysFile(name, walletInfo.type);

    ElectrumWalletSnapshot? snp;

    try {
      snp = await ElectrumWalletSnapshot.load(
        encryptionFileUtils,
        name,
        walletInfo.type,
        password,
        BitcoinCashNetwork.mainnet,
      );
    } catch (e) {
      if (!hasKeysFile) {
        rethrow;
      }
    }

    final WalletKeysData keysData;
    // Migrate wallet from the old scheme to then new .keys file scheme
    if (!hasKeysFile) {
      keysData =
          WalletKeysData(mnemonic: snp!.mnemonic, xPub: snp.xpub, passphrase: snp.passphrase);
    } else {
      keysData = await WalletKeysFile.readKeysFile(
        name,
        walletInfo.type,
        password,
        encryptionFileUtils,
      );
    }

    return BitcoinCashWallet(
      mnemonic: keysData.mnemonic!,
      password: password,
      walletInfo: walletInfo,
      derivationInfo: await walletInfo.getDerivationInfo(),
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: snp?.addresses.map((addr) {
        try {
          BitcoinCashAddress(addr.address);
          return BitcoinAddressRecord(
            addr.address,
            index: addr.index,
            isHidden: addr.isHidden,
            name: addr.name,
            type: P2pkhAddressType.p2pkh,
            network: BitcoinCashNetwork.mainnet,
          );
        } catch (_) {
          return BitcoinAddressRecord(
            AddressUtils.getCashAddrFormat(addr.address),
            index: addr.index,
            isHidden: addr.isHidden,
            name: addr.name,
            type: P2pkhAddressType.p2pkh,
            network: BitcoinCashNetwork.mainnet,
          );
        }
      }).toList(),
      initialBalance: snp?.balance,
      seedBytes: MnemonicBip39.toSeed(keysData.mnemonic!, passphrase: keysData.passphrase),
      encryptionFileUtils: encryptionFileUtils,
      initialRegularAddressIndex: snp?.regularAddressIndex,
      initialChangeAddressIndex: snp?.changeAddressIndex,
      addressPageType: P2pkhAddressType.p2pkh,
      passphrase: keysData.passphrase,
    );
  }

  bitbox.ECPair generateKeyPair({required Bip32Slip10Secp256k1 hd, required int index}) =>
      bitbox.ECPair.fromPrivateKey(
        Uint8List.fromList(hd.childKey(Bip32KeyIndex(index)).privateKey.raw),
      );

  @override
  int calculateEstimatedFeeWithFeeRate(int feeRate, int? amount, {int? outputsCount, int? size}) {
    var inputsCount = 0;
    var totalValue = 0;

    for (final input in unspentCoins) {
      if (input.isSending) {
        inputsCount++;
        totalValue += input.value;
      }
      if (amount != null && totalValue >= amount) {
        break;
      }
    }

    if (amount != null && totalValue < amount) {
      return 0;
    }

    final _outputsCount = outputsCount ?? (amount != null ? 2 : 1);

    return feeAmountWithFeeRate(feeRate, inputsCount, _outputsCount);
  }

  @override
  int feeRate(TransactionPriority priority) {
    if (priority is BitcoinCashTransactionPriority) {
      switch (priority) {
        case BitcoinCashTransactionPriority.slow:
          return 1;
        case BitcoinCashTransactionPriority.medium:
          return 5;
        case BitcoinCashTransactionPriority.fast:
          return 10;
      }
    }

    return 0;
  }

  @override
  Future<String> signMessage(String message, {String? address}) async {
    int? index;
    try {
      index = address != null
          ? walletAddresses.allAddresses.firstWhere((element) => element.address == address).index
          : null;
    } catch (_) {}
    final hd = index == null ? mainHd : mainHd.childKey(Bip32KeyIndex(index));
    final privateKey = ECPrivate.fromWif(
      WifEncoder.encode(hd.privateKey.raw, netVer: network.wifNetVer),
      netVersion: network.wifNetVer,
    );
    return privateKey.signMessage(StringUtils.encode(message));
  }
}
