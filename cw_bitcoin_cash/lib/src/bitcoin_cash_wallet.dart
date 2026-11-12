import "package:bitbox/bitbox.dart" as bitbox;
import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_mnemonics_bip39.dart";
import "package:cw_bitcoin/bitcoin_transaction_priority.dart";
import "package:cw_bitcoin/electrum_balance.dart";
import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_bitcoin/electrum_wallet_snapshot.dart";
import "package:cw_bitcoin/hardware/bitcoin_hardware_wallet_service.dart";
import "package:cw_bitcoin/output_ordering.dart";
import "package:cw_bitcoin/psbt/transaction_builder.dart";
import "package:cw_bitcoin_cash/src/bitcoin_cash_base.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/encryption_file_utils.dart";
import "package:cw_core/output_info.dart";
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
    required String password,
    required WalletInfo walletInfo,
    required DerivationInfo derivationInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required EncryptionFileUtils encryptionFileUtils,
    String? mnemonic,
    Uint8List? seedBytes,
    String? xpub,
    String? passphrase,
    BitcoinAddressType? addressPageType,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
  }) : super(
          mnemonic: mnemonic,
          xpub: xpub,
          password: password,
          walletInfo: walletInfo,
          derivationInfo: derivationInfo,
          unspentCoinsInfo: unspentCoinsInfo,
          network: BitcoinCashNetwork.mainnet,
          initialAddresses: initialAddresses,
          initialBalance: initialBalance,
          seedBytes: seedBytes,
          currency: CryptoCurrency.bch,
          encryptionFileUtils: encryptionFileUtils,
          passphrase: passphrase,
        ) {
    walletAddresses = BitcoinCashWalletAddresses(
      walletInfo,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      mainHdByTypeAndAccount: mainHdByTypeAndAccount,
      sideHdByTypeAndAccount: sideHdByTypeAndAccount,
      accountIndexes: [currentAccountIndex],
      currentAccountIndex: currentAccountIndex,
      legacyMainHd: mainHd,
      legacySideHd: sideHd,
      network: network,
      initialAddressPageType: addressPageType,
      isHardwareWallet: walletInfo.isHardwareWallet,
    );
    autorun((_) {
      walletAddresses.isEnabledAutoGenerateSubaddress = isEnabledAutoGenerateSubaddress;
    });
  }

  static Future<BitcoinCashWallet> create(
      {required String mnemonic,
      required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      required EncryptionFileUtils encryptionFileUtils,
      String? passphrase,
      String? addressPageType,
      List<BitcoinAddressRecord>? initialAddresses,
      ElectrumBalance? initialBalance,
      Map<String, int>? initialRegularAddressIndex,
      Map<String, int>? initialChangeAddressIndex}) async {
    return BitcoinCashWallet(
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
  }

  static Future<BitcoinCashWallet> open({
    required String name,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required String password,
    required EncryptionFileUtils encryptionFileUtils,
  }) async {
    final hasKeysFile = await WalletKeysFile.hasKeysFile(name, walletInfo.type);

    ElectrumWalletSnapshot? snp = null;

    try {
      snp = await ElectrumWalletSnapshot.load(
        encryptionFileUtils,
        name,
        walletInfo.type,
        password,
        BitcoinCashNetwork.mainnet,
      );
    } catch (e) {
      if (!hasKeysFile) rethrow;
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
      mnemonic: keysData.mnemonic,
      xpub: keysData.xPub,
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
            isHiddenChecked: addr.isHiddenChecked,
            name: addr.name,
            type: P2pkhAddressType.p2pkh,
            network: BitcoinCashNetwork.mainnet,
          );
        } catch (_) {
          return BitcoinAddressRecord(
            AddressUtils.getCashAddrFormat(addr.address),
            index: addr.index,
            isHidden: addr.isHidden,
            isHiddenChecked: addr.isHiddenChecked,
            name: addr.name,
            type: P2pkhAddressType.p2pkh,
            network: BitcoinCashNetwork.mainnet,
          );
        }
      }).toList(),
      initialBalance: snp?.balance,
      seedBytes: keysData.mnemonic == null
          ? null
          : MnemonicBip39.toSeed(keysData.mnemonic!, passphrase: keysData.passphrase),
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
    int inputsCount = 0;
    int totalValue = 0;

    for (final input in unspentCoins) {
      if (input.isSending) {
        inputsCount++;
        totalValue += input.value;
      }
      if (amount != null && totalValue >= amount) {
        break;
      }
    }

    if (amount != null && totalValue < amount) return 0;

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
  Future<String> signMessage(String message, {String? address = null}) async {
    int? index;
    try {
      index = address != null
          ? walletAddresses.allAddresses.firstWhere((element) => element.address == address).index
          : null;
    } catch (_) {}
    final HD = index == null ? mainHd : mainHd.childKey(Bip32KeyIndex(index));
    final priv = ECPrivate.fromWif(
      WifEncoder.encode(HD.privateKey.raw, netVer: network.wifNetVer),
      netVersion: network.wifNetVer,
    );
    return priv.signMessage(StringUtils.encode(message));
  }

  @override
  Future<BtcTransaction> buildHardwareWalletTransaction({
    required List<BitcoinOutput> outputs,
    required BigInt fee,
    required BasedUtxoNetwork network,
    required List<UtxoWithAddress> utxos,
    required List<OutputInfo> cwOutputs,
    required Map<String, PublicKeyWithDerivationPath> publicKeys,
    String? memo,
    bool enableRBF = false,
    BitcoinOrdering inputOrdering = BitcoinOrdering.bip69,
    BitcoinOrdering outputOrdering = BitcoinOrdering.bip69,
  }) async {
    final masterFingerprint =
        await (hardwareWalletService! as BitcoinHardwareWalletService).getMasterFingerprint();

    final readyInputs = <PSBTReadyUtxoWithAddress>[];
    for (final utxo in utxos) {
      final rawTx = await electrumClient.getTransactionHex(hash: utxo.utxo.txHash);
      final publicKeyAndDerivationPath = publicKeys[utxo.ownerDetails.address.pubKeyHash()]!;

      readyInputs.add(
        PSBTReadyUtxoWithAddress(
          utxo: utxo.utxo,
          rawTx: rawTx,
          ownerDetails: utxo.ownerDetails,
          ownerDerivationPath: publicKeyAndDerivationPath.derivationPath,
          ownerMasterFingerprint: masterFingerprint,
          ownerPublicKey: publicKeyAndDerivationPath.publicKey,
        ),
      );
    }

    final orderedOutputs = orderOutputs(outputs, outputOrdering).map((o) {
      if (o.isChange && publicKeys.containsKey(o.address.pubKeyHash())) {
        final changeKey = publicKeys[o.address.pubKeyHash()]!;
        return PSBTReadyBitcoinOutput(
          address: o.address,
          value: o.value,
          isSilentPayment: o.isSilentPayment,
          isChange: o.isChange,
          changeMasterFingerprint: masterFingerprint,
          changeDerivationPath: changeKey.derivationPath,
          changePublicKey: changeKey.publicKey,
        );
      }
      return PSBTReadyBitcoinOutput.fromOutput(o);
    });

    final rawHex = await (hardwareWalletService! as BitcoinCashHardwareWalletService)
        .signBitcoinCashTransaction(
      outputs: orderedOutputs.toList(),
      inputs: readyInputs,
      publicKeys: publicKeys,
    );

    return BtcTransaction.fromRaw(rawHex);
  }
}
