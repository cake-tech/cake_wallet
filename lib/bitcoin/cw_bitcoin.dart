part of 'bitcoin.dart';

class CWBitcoin extends Bitcoin {
  WalletCredentials createBitcoinRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    required DerivationType derivationType,
    required String derivationPath,
  }) =>
      BitcoinRestoreWalletFromSeedCredentials(
          name: name,
          mnemonic: mnemonic,
          password: password,
          derivationType: derivationType,
          derivationPath: derivationPath);

  @override
  WalletCredentials createBitcoinRestoreWalletFromWIFCredentials(
          {required String name,
          required String password,
          required String wif,
          WalletInfo? walletInfo}) =>
      BitcoinRestoreWalletFromWIFCredentials(
          name: name, password: password, wif: wif, walletInfo: walletInfo);

  @override
  WalletCredentials createBitcoinNewWalletCredentials(
          {required String name, WalletInfo? walletInfo}) =>
      BitcoinNewWalletCredentials(name: name, walletInfo: walletInfo);

  @override
  TransactionPriority getMediumTransactionPriority() => BitcoinTransactionPriority.medium;

  @override
  List<String> getWordList() => wordlist;

  @override
  Map<String, String> getWalletKeys(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    final keys = bitcoinWallet.keys;

    return <String, String>{
      'wif': keys.wif,
      'privateKey': keys.privateKey,
      'publicKey': keys.publicKey
    };
  }

  @override
  List<TransactionPriority> getTransactionPriorities() => BitcoinTransactionPriority.all;

  @override
  List<TransactionPriority> getLitecoinTransactionPriorities() => LitecoinTransactionPriority.all;

  @override
  TransactionPriority deserializeBitcoinTransactionPriority(int raw) =>
      BitcoinTransactionPriority.deserialize(raw: raw);

  @override
  TransactionPriority deserializeLitecoinTransactionPriority(int raw) =>
      LitecoinTransactionPriority.deserialize(raw: raw);

  @override
  int getFeeRate(Object wallet, TransactionPriority priority) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.feeRate(priority);
  }

  @override
  Future<void> generateNewAddress(Object wallet, String label) async {
    final bitcoinWallet = wallet as ElectrumWallet;
    await bitcoinWallet.walletAddresses.generateNewAddress(label: label);
    await wallet.save();
  }

  @override
  Future<void> updateAddress(Object wallet, String address, String label) async {
    final bitcoinWallet = wallet as ElectrumWallet;
    bitcoinWallet.walletAddresses.updateAddress(address, label);
    await wallet.save();
  }

  @override
  Object createBitcoinTransactionCredentials(List<Output> outputs,
          {required TransactionPriority priority, int? feeRate}) =>
      BitcoinTransactionCredentials(
          outputs
              .map((out) => OutputInfo(
                  fiatAmount: out.fiatAmount,
                  cryptoAmount: out.cryptoAmount,
                  address: out.address,
                  note: out.note,
                  sendAll: out.sendAll,
                  extractedAddress: out.extractedAddress,
                  isParsedAddress: out.isParsedAddress,
                  formattedCryptoAmount: out.formattedCryptoAmount))
              .toList(),
          priority: priority as BitcoinTransactionPriority,
          feeRate: feeRate);

  @override
  Object createBitcoinTransactionCredentialsRaw(List<OutputInfo> outputs,
          {TransactionPriority? priority, required int feeRate}) =>
      BitcoinTransactionCredentials(outputs,
          priority: priority != null ? priority as BitcoinTransactionPriority : null,
          feeRate: feeRate);

  @override
  List<String> getAddresses(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.walletAddresses.addressesByReceiveType
        .map((BitcoinAddressRecord addr) => addr.address)
        .toList();
  }

  @override
  @computed
  List<ElectrumSubAddress> getSubAddresses(Object wallet) {
    final electrumWallet = wallet as ElectrumWallet;
    return electrumWallet.walletAddresses.addressesByReceiveType
        .map((BitcoinAddressRecord addr) => ElectrumSubAddress(
            id: addr.index,
            name: addr.name,
            address: electrumWallet.type == WalletType.bitcoinCash ? addr.cashAddr : addr.address,
            txCount: addr.txCount,
            balance: addr.balance,
            isChange: addr.isHidden))
        .toList();
  }

  @override
  String getAddress(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.walletAddresses.address;
  }

  @override
  String formatterBitcoinAmountToString({required int amount}) =>
      bitcoinAmountToString(amount: amount);

  @override
  double formatterBitcoinAmountToDouble({required int amount}) =>
      bitcoinAmountToDouble(amount: amount);

  @override
  int formatterStringDoubleToBitcoinAmount(String amount) => stringDoubleToBitcoinAmount(amount);

  @override
  String bitcoinTransactionPriorityWithLabel(TransactionPriority priority, int rate) =>
      (priority as BitcoinTransactionPriority).labelWithRate(rate);

  @override
  List<BitcoinUnspent> getUnspents(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.unspentCoins;
  }

  Future<void> updateUnspents(Object wallet) async {
    final bitcoinWallet = wallet as ElectrumWallet;
    await bitcoinWallet.updateUnspent();
  }

  WalletService createBitcoinWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource) {
    return BitcoinWalletService(walletInfoSource, unspentCoinSource);
  }

  WalletService createLitecoinWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource) {
    return LitecoinWalletService(walletInfoSource, unspentCoinSource);
  }

  @override
  TransactionPriority getBitcoinTransactionPriorityMedium() => BitcoinTransactionPriority.medium;

  @override
  TransactionPriority getLitecoinTransactionPriorityMedium() => LitecoinTransactionPriority.medium;

  @override
  TransactionPriority getBitcoinTransactionPrioritySlow() => BitcoinTransactionPriority.slow;

  @override
  TransactionPriority getLitecoinTransactionPrioritySlow() => LitecoinTransactionPriority.slow;

  @override
  Future<void> setAddressType(Object wallet, dynamic option) async {
    final bitcoinWallet = wallet as ElectrumWallet;
    await bitcoinWallet.walletAddresses.setAddressType(option as BitcoinAddressType);
  }

  @override
  ReceivePageOption getSelectedAddressType(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return BitcoinReceivePageOption.fromType(bitcoinWallet.walletAddresses.addressPageType);
  }

  @override
  List<ReceivePageOption> getBitcoinReceivePageOptions() => BitcoinReceivePageOption.all;

  @override
  BitcoinAddressType getBitcoinAddressType(ReceivePageOption option) {
    switch (option) {
      case BitcoinReceivePageOption.p2pkh:
        return P2pkhAddressType.p2pkh;
      case BitcoinReceivePageOption.p2sh:
        return P2shAddressType.p2wpkhInP2sh;
      case BitcoinReceivePageOption.p2tr:
        return SegwitAddresType.p2tr;
      case BitcoinReceivePageOption.p2wsh:
        return SegwitAddresType.p2wsh;
      case BitcoinReceivePageOption.p2wpkh:
      default:
        return SegwitAddresType.p2wpkh;
    }
  }

  @override
  Future<List<DerivationType>> compareDerivationMethods(
      {required String mnemonic, required Node node}) async {
    if (await checkIfMnemonicIsElectrum2(mnemonic)) {
      return [DerivationType.electrum2];
    }

    return [DerivationType.bip39, DerivationType.electrum2];
  }

  int _countOccurrences(String str, String charToCount) {
    int count = 0;
    for (int i = 0; i < str.length; i++) {
      if (str[i] == charToCount) {
        count++;
      }
    }
    return count;
  }

  @override
  Future<List<DerivationInfo>> getDerivationsFromMnemonic(
      {required String mnemonic, required Node node}) async {
    List<DerivationInfo> list = [];

    final electrumClient = ElectrumClient();
    await electrumClient.connectToUri(node.uri);

    for (DerivationType dType in bitcoin_derivations.keys) {
      late Uint8List seedBytes;
      if (dType == DerivationType.electrum2) {
        seedBytes = await mnemonicToSeedBytes(mnemonic);
      } else if (dType == DerivationType.bip39) {
        seedBytes = bip39.mnemonicToSeed(mnemonic);
      }

      for (DerivationInfo dInfo in bitcoin_derivations[dType]!) {
        try {
          DerivationInfo dInfoCopy = DerivationInfo(
            derivationType: dInfo.derivationType,
            derivationPath: dInfo.derivationPath,
            description: dInfo.description,
            script_type: dInfo.script_type,
          );
          var node = bip32.BIP32.fromSeed(seedBytes);

          String derivationPath = dInfoCopy.derivationPath!;
          int derivationDepth = _countOccurrences(derivationPath, "/");
          if (derivationDepth == 3) {
            derivationPath += "/0/0";
            dInfoCopy.derivationPath = dInfoCopy.derivationPath! + "/0";
          }
          node = node.derivePath(derivationPath);

          String? address;
          switch (dInfoCopy.script_type) {
            case "p2wpkh":
              address = btc
                  .P2WPKH(
                    data: new btc.PaymentData(pubkey: node.publicKey),
                    network: btc.bitcoin,
                  )
                  .data
                  .address;
              break;
            case "p2pkh":
            default:
              address = btc
                  .P2PKH(
                    data: new btc.PaymentData(pubkey: node.publicKey),
                    network: btc.bitcoin,
                  )
                  .data
                  .address;
              break;
          }

          final sh = scriptHash(address!, network: BitcoinNetwork.mainnet);
          final history = await electrumClient.getHistory(sh);

          final balance = await electrumClient.getBalance(sh);
          dInfoCopy.balance = balance.entries.first.value.toString();
          dInfoCopy.address = address;
          dInfoCopy.height = history.length;

          list.add(dInfoCopy);
        } catch (e) {
          print(e);
        }
      }
    }

    // sort the list such that derivations with the most transactions are first:
    list.sort((a, b) => b.height.compareTo(a.height));

    return list;
  }
}
