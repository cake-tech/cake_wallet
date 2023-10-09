part of 'bitcoin.dart';

class CWBitcoin extends Bitcoin {
  @override
  TransactionPriority getMediumTransactionPriority() => BitcoinTransactionPriority.medium;

  @override
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

  String bitcoinTransactionPriorityWithLabel(TransactionPriority priority, int rate) =>
      (priority as BitcoinTransactionPriority).labelWithRate(rate);

  void updateUnspents(Object wallet) async {
    final bitcoinWallet = wallet as ElectrumWallet;
    await bitcoinWallet.updateUnspent();
  }

  WalletService createLitecoinWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource) {
    return LitecoinWalletService(walletInfoSource, unspentCoinSource);
  }

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
  Future<void> generateNewAddress(Object wallet) async {
    final bitcoinWallet = wallet as ElectrumWallet;
    await bitcoinWallet.walletAddresses.generateNewAddress();
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
    return bitcoinWallet.walletAddresses.addresses
        .map((BitcoinAddressRecord addr) => addr.address)
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
  List<Unspent> getUnspents(Object wallet) {
    final bitcoinWallet = wallet as ElectrumWallet;
    return bitcoinWallet.unspentCoins
        .map((BitcoinUnspent bitcoinUnspent) => Unspent(bitcoinUnspent.address.address,
            bitcoinUnspent.hash, bitcoinUnspent.value, bitcoinUnspent.vout, null))
        .toList();
  }

  WalletService createBitcoinWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource) {
    return BitcoinWalletService(walletInfoSource, unspentCoinSource);
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
  Future<List<DerivationType>> compareDerivationMethods(
      {required String mnemonic, required Node node}) async {
    if (await checkIfMnemonicIsElectrum2(mnemonic)) {
      return [DerivationType.electrum2];
    }

    return [DerivationType.bip39, DerivationType.electrum2];
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
          int derivationDepth = countOccurrences(derivationPath, "/");
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
            // case "p2wpkh-p2sh":// TODO
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

          final sh = scriptHash(address!, networkType: btc.bitcoin);
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
