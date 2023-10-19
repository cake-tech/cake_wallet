part of 'nano.dart';

class CWNanoAccountList extends NanoAccountList {
  CWNanoAccountList(this._wallet);
  final Object _wallet;

  @override
  @computed
  ObservableList<NanoAccount> get accounts {
    final nanoWallet = _wallet as NanoWallet;
    final accounts = nanoWallet.walletAddresses.accountList.accounts
        .map((acc) => NanoAccount(id: acc.id, label: acc.label, balance: acc.balance))
        .toList();
    return ObservableList<NanoAccount>.of(accounts);
  }

  @override
  void update(Object wallet) {
    final nanoWallet = wallet as NanoWallet;
    nanoWallet.walletAddresses.accountList.update(null);
  }

  @override
  void refresh(Object wallet) {
    final nanoWallet = wallet as NanoWallet;
    nanoWallet.walletAddresses.accountList.refresh();
  }

  @override
  Future<List<NanoAccount>> getAll(Object wallet) async {
    final nanoWallet = wallet as NanoWallet;
    return (await nanoWallet.walletAddresses.accountList.getAll())
        .map((acc) => NanoAccount(id: acc.id, label: acc.label, balance: acc.balance))
        .toList();
  }

  @override
  Future<void> addAccount(Object wallet, {required String label}) async {
    final nanoWallet = wallet as NanoWallet;
    await nanoWallet.walletAddresses.accountList.addAccount(label: label);
  }

  @override
  Future<void> setLabelAccount(Object wallet,
      {required int accountIndex, required String label}) async {
    final nanoWallet = wallet as NanoWallet;
    await nanoWallet.walletAddresses.accountList
        .setLabelAccount(accountIndex: accountIndex, label: label);
  }
}

class CWNano extends Nano {
  @override
  NanoAccountList getAccountList(Object wallet) {
    return CWNanoAccountList(wallet);
  }

  @override
  Account getCurrentAccount(Object wallet) {
    final nanoWallet = wallet as NanoWallet;
    final acc = nanoWallet.walletAddresses.account;
    return Account(id: acc!.id, label: acc.label, balance: acc.balance);
  }

  @override
  void setCurrentAccount(Object wallet, int id, String label, String? balance) {
    final nanoWallet = wallet as NanoWallet;
    nanoWallet.walletAddresses.account = NanoAccount(id: id, label: label, balance: balance);
    nanoWallet.regenerateAddress();
  }

  @override
  List<String> getNanoWordList(String language) {
    return NanoMnemomics.WORDLIST;
  }

  @override
  WalletService createNanoWalletService(Box<WalletInfo> walletInfoSource) {
    return NanoWalletService(walletInfoSource);
  }

  @override
  Map<String, String> getKeys(Object wallet) {
    final nanoWallet = wallet as NanoWallet;
    final keys = nanoWallet.keys;
    return <String, String>{
      "seedKey": keys.seedKey,
    };
  }

  @override
  WalletCredentials createNanoNewWalletCredentials({
    required String name,
    String? password,
  }) =>
      NanoNewWalletCredentials(
        name: name,
        password: password,
      );

  @override
  WalletCredentials createNanoRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required String mnemonic,
    DerivationType? derivationType,
  }) {
    if (derivationType == null) {
      // figure out the derivation type as best we can, otherwise set it to "unknown"
      if (mnemonic.split(" ").length == 12) {
        derivationType = DerivationType.bip39;
      } else {
        derivationType = DerivationType.unknown;
      }
    }

    return NanoRestoreWalletFromSeedCredentials(
      name: name,
      password: password,
      mnemonic: mnemonic,
      derivationType: derivationType,
    );
  }

  @override
  WalletCredentials createNanoRestoreWalletFromKeysCredentials({
    required String name,
    required String password,
    required String seedKey,
    DerivationType? derivationType,
  }) {
    if (derivationType == null) {
      // figure out the derivation type as best we can, otherwise set it to "unknown"
      if (seedKey.length == 64) {
        derivationType = DerivationType.nano;
      } else {
        derivationType = DerivationType.unknown;
      }
    }

    return NanoRestoreWalletFromKeysCredentials(
      name: name,
      password: password,
      seedKey: seedKey,
      derivationType: derivationType,
    );
  }

  @override
  Object createNanoTransactionCredentials(List<Output> outputs) {
    return NanoTransactionCredentials(
      outputs
          .map((out) => OutputInfo(
                fiatAmount: out.fiatAmount,
                cryptoAmount: out.cryptoAmount,
                address: out.address,
                note: out.note,
                sendAll: out.sendAll,
                extractedAddress: out.extractedAddress,
                isParsedAddress: out.isParsedAddress,
                formattedCryptoAmount: out.formattedCryptoAmount,
              ))
          .toList(),
    );
  }

  @override
  Future<void> changeRep(Object wallet, String address) async {
    return (wallet as NanoWallet).changeRep(address);
  }

  @override
  Future<void> updateTransactions(Object wallet) async {
    return (wallet as NanoWallet).updateTransactions();
  }

  @override
  BigInt getTransactionAmountRaw(TransactionInfo transactionInfo) {
    return (transactionInfo as NanoTransactionInfo).amountRaw;
  }

  @override
  String getRepresentative(Object wallet) {
    return (wallet as NanoWallet).representative;
  }
}

class CWNanoUtil extends NanoUtil {
  // standard:
  @override
  String seedToPrivate(String seed, int index) {
    return ND.NanoKeys.seedToPrivate(seed, index);
  }

  @override
  String seedToAddress(String seed, int index) {
    return ND.NanoAccounts.createAccount(
        ND.NanoAccountType.NANO, privateKeyToPublic(seedToPrivate(seed, index)));
  }

  @override
  String seedToMnemonic(String seed) {
    return NanoMnemomics.seedToMnemonic(seed).join(" ");
  }

  @override
  Future<String> mnemonicToSeed(String mnemonic) async {
    return NanoMnemomics.mnemonicListToSeed(mnemonic.split(' '));
  }

  @override
  String privateKeyToPublic(String privateKey) {
    // return NanoHelpers.byteToHex(Ed25519Blake2b.getPubkey(NanoHelpers.hexToBytes(privateKey))!);
    return ND.NanoKeys.createPublicKey(privateKey);
  }

  @override
  String addressToPublicKey(String publicAddress) {
    return ND.NanoAccounts.extractPublicKey(publicAddress);
  }

  // universal:
  @override
  String privateKeyToAddress(String privateKey) {
    return ND.NanoAccounts.createAccount(ND.NanoAccountType.NANO, privateKeyToPublic(privateKey));
  }

  @override
  String publicKeyToAddress(String publicKey) {
    return ND.NanoAccounts.createAccount(ND.NanoAccountType.NANO, publicKey);
  }

  // standard + hd:
  @override
  bool isValidSeed(String seed) {
    // Ensure seed is 64 or 128 characters long
    if (seed.length != 64 && seed.length != 128) {
      return false;
    }
    // Ensure seed only contains hex characters, 0-9;A-F
    return ND.NanoHelpers.isHexString(seed);
  }

  // hd:
  @override
  Future<String> hdMnemonicListToSeed(List<String> words) async {
    // if (words.length != 24) {
    //   throw Exception('Expected a 24-word list, got a ${words.length} list');
    // }
    final Uint8List salt = Uint8List.fromList(utf8.encode('mnemonic'));
    final Pbkdf2 hasher = Pbkdf2(iterations: 2048);
    final String seed = await hasher.sha512(words.join(' '), salt);
    return seed;
  }

  @override
  Future<String> hdSeedToPrivate(String seed, int index) async {
    List<int> seedBytes = hex.decode(seed);
    KeyData data = await ED25519_HD_KEY.derivePath("m/44'/165'/$index'", seedBytes);
    return hex.encode(data.key);
  }

  @override
  Future<String> hdSeedToAddress(String seed, int index) async {
    return ND.NanoAccounts.createAccount(
        ND.NanoAccountType.NANO, privateKeyToPublic(await hdSeedToPrivate(seed, index)));
  }

  @override
  Future<String> uniSeedToAddress(String seed, int index, String type) {
    if (type == "standard") {
      return Future<String>.value(seedToAddress(seed, index));
    } else if (type == "hd") {
      return hdSeedToAddress(seed, index);
    } else {
      throw Exception('Unknown seed type');
    }
  }

  @override
  Future<String> uniSeedToPrivate(String seed, int index, String type) {
    if (type == "standard") {
      return Future<String>.value(seedToPrivate(seed, index));
    } else if (type == "hd") {
      return hdSeedToPrivate(seed, index);
    } else {
      throw Exception('Unknown seed type');
    }
  }

  @override
  bool isValidBip39Seed(String seed) {
    // Ensure seed is 128 characters long
    if (seed.length != 128) {
      return false;
    }
    // Ensure seed only contains hex characters, 0-9;A-F
    return ND.NanoHelpers.isHexString(seed);
  }

  // number util:

  static const int maxDecimalDigits = 6; // Max digits after decimal
  BigInt rawPerNano = BigInt.parse("1000000000000000000000000000000");
  BigInt rawPerNyano = BigInt.parse("1000000000000000000000000");
  BigInt rawPerBanano = BigInt.parse("100000000000000000000000000000");
  BigInt rawPerXMR = BigInt.parse("1000000000000");
  BigInt convertXMRtoNano = BigInt.parse("1000000000000000000");
  // static BigInt convertXMRtoNano = BigInt.parse("1000000000000000000000000000");

  /// Convert raw to ban and return as BigDecimal
  ///
  /// @param raw 100000000000000000000000000000
  /// @return Decimal value 1.000000000000000000000000000000
  ///
  Decimal _getRawAsDecimal(String? raw, BigInt? rawPerCur) {
    rawPerCur ??= rawPerNano;
    final Decimal amount = Decimal.parse(raw.toString());
    final Decimal result = (amount / Decimal.parse(rawPerCur.toString())).toDecimal();
    return result;
  }

  @override
  String getRawAsDecimalString(String? raw, BigInt? rawPerCur) {
    final Decimal result = _getRawAsDecimal(raw, rawPerCur);
    return result.toString();
  }

  @override
  String truncateDecimal(Decimal input, {int digits = maxDecimalDigits}) {
    Decimal bigger = input.shift(digits);
    bigger = bigger.floor(); // chop off the decimal: 1.059 -> 1.05
    bigger = bigger.shift(-digits);
    return bigger.toString();
  }

  /// Return raw as a NANO amount.
  ///
  /// @param raw 100000000000000000000000000000
  /// @returns 1
  ///
  @override
  String getRawAsUsableString(String? raw, BigInt rawPerCur) {
    final String res =
        truncateDecimal(_getRawAsDecimal(raw, rawPerCur), digits: maxDecimalDigits + 9);

    if (raw == null || raw == "0" || raw == "00000000000000000000000000000000") {
      return "0";
    }

    if (!res.contains(".")) {
      return res;
    }

    final String numAmount = res.split(".")[0];
    String decAmount = res.split(".")[1];

    // truncate:
    if (decAmount.length > maxDecimalDigits) {
      decAmount = decAmount.substring(0, maxDecimalDigits);
      // remove trailing zeros:
      decAmount = decAmount.replaceAllMapped(RegExp(r'0+$'), (Match match) => '');
      if (decAmount.isEmpty) {
        return numAmount;
      }
    }

    return "$numAmount.$decAmount";
  }

  @override
  String getRawAccuracy(String? raw, BigInt rawPerCur) {
    final String rawString = getRawAsUsableString(raw, rawPerCur);
    final String rawDecimalString = _getRawAsDecimal(raw, rawPerCur).toString();

    if (raw == null || raw.isEmpty || raw == "0") {
      return "";
    }

    if (rawString != rawDecimalString) {
      return "~";
    }
    return "";
  }

  /// Return readable string amount as raw string
  /// @param amount 1.01
  /// @returns  101000000000000000000000000000
  ///
  @override
  String getAmountAsRaw(String amount, BigInt rawPerCur) {
    final Decimal asDecimal = Decimal.parse(amount);
    final Decimal rawDecimal = Decimal.parse(rawPerCur.toString());
    return (asDecimal * rawDecimal).toString();
  }

  @override
  Future<AccountInfoResponse?> getInfoFromSeedOrMnemonic(
    DerivationType derivationType, {
    String? seedKey,
    String? mnemonic,
    required Node node,
  }) async {
    NanoClient nanoClient = NanoClient();
    nanoClient.connect(node);
    late String publicAddress;

    if (seedKey != null) {
      if (seedKey.length == 64) {
        try {
          mnemonic = nanoUtil!.seedToMnemonic(seedKey);
        } catch (e) {
          print("not a valid 'nano' seed key");
        }
      }
      if (derivationType == DerivationType.bip39) {
        publicAddress = await hdSeedToAddress(seedKey, 0);
      } else if (derivationType == DerivationType.nano) {
        publicAddress = await seedToAddress(seedKey, 0);
      }
    }

    if (derivationType == DerivationType.bip39) {
      if (mnemonic != null) {
        seedKey = await hdMnemonicListToSeed(mnemonic.split(' '));
        publicAddress = await hdSeedToAddress(seedKey, 0);
      }
    }

    if (derivationType == DerivationType.nano) {
      if (mnemonic != null) {
        seedKey = await mnemonicToSeed(mnemonic);
        publicAddress = await seedToAddress(seedKey, 0);
      }
    }

    AccountInfoResponse? accountInfo = await nanoClient.getAccountInfo(publicAddress);
    if (accountInfo == null) {
      accountInfo = AccountInfoResponse(
          frontier: "", balance: "0", representative: "", confirmationHeight: 0);
    }
    accountInfo.address = publicAddress;
    return accountInfo;
  }

  @override
  Future<List<DerivationType>> compareDerivationMethods({
    String? mnemonic,
    String? privateKey,
    required Node node,
  }) async {
    String? seedKey = privateKey;

    if (mnemonic?.split(' ').length == 12) {
      return [DerivationType.bip39];
    }
    if (seedKey?.length == 128) {
      return [DerivationType.bip39];
    } else if (seedKey?.length == 64) {
      try {
        mnemonic = nanoUtil!.seedToMnemonic(seedKey!);
      } catch (e) {
        print("not a valid 'nano' seed key");
      }
    }

    late String publicAddressStandard;
    late String publicAddressBip39;

    try {
      NanoClient nanoClient = NanoClient();
      nanoClient.connect(node);

      if (mnemonic != null) {
        seedKey = await hdMnemonicListToSeed(mnemonic.split(' '));
        publicAddressBip39 = await hdSeedToAddress(seedKey, 0);

        seedKey = await mnemonicToSeed(mnemonic);
        publicAddressStandard = await seedToAddress(seedKey, 0);
      } else if (seedKey != null) {
        try {
          publicAddressBip39 = await hdSeedToAddress(seedKey, 0);
        } catch (e) {
          return [DerivationType.nano];
        }
        try {
          publicAddressStandard = await seedToAddress(seedKey, 0);
        } catch (e) {
          return [DerivationType.bip39];
        }
      }

      // check if account has a history:
      AccountInfoResponse? bip39Info;
      AccountInfoResponse? standardInfo;

      try {
        bip39Info = await nanoClient.getAccountInfo(publicAddressBip39);
      } catch (e) {
        bip39Info = null;
      }
      try {
        standardInfo = await nanoClient.getAccountInfo(publicAddressStandard);
      } catch (e) {
        standardInfo = null;
      }

      // one of these is *probably* null:
      if (bip39Info == null && standardInfo != null) {
        return [DerivationType.nano];
      } else if (standardInfo == null && bip39Info != null) {
        return [DerivationType.bip39];
      }

      // we don't know for sure:
      return [DerivationType.nano, DerivationType.bip39];
    } catch (e) {
      return [DerivationType.nano, DerivationType.bip39];
    }
  }
}
