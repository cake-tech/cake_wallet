import 'dart:convert';
import 'dart:typed_data';
import 'package:cake_wallet/core/bitcoin_transaction_history.dart';
import 'package:cake_wallet/core/transaction_history.dart';
import 'package:mobx/mobx.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_flutter/src/payments/index.dart' show PaymentData;
import 'package:cake_wallet/bitcoin/file.dart';
import 'package:cake_wallet/src/domain/common/pathForWallet.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/bitcoin/electrum.dart';
import 'package:cake_wallet/bitcoin/bitcoin_balance.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'wallet_base.dart';

part 'bitcoin_wallet.g.dart';

/* TODO: Save balance to a wallet file.
  Load balance from the wallet file in `init` method.
*/

class BitcoinWallet = BitcoinWalletBase with _$BitcoinWallet;

abstract class BitcoinWalletBase extends WalletBase<BitcoinBalance> with Store {
  static Future<BitcoinWalletBase> load(
      {@required String name, @required String password}) async {
    final walletDirPath =
        await pathForWalletDir(name: name, type: WalletType.bitcoin);
    final walletPath = '$walletDirPath/$name';
    final walletJSONRaw = await read(path: walletPath, password: password);
    final jsoned = json.decode(walletJSONRaw) as Map<String, Object>;
    final mnemonic = jsoned['mnemonic'] as String;
    final accountIndex =
        (jsoned['account_index'] == "null" || jsoned['account_index'] == null)
            ? 0
            : int.parse(jsoned['account_index'] as String);

    return BitcoinWalletBase.build(
        mnemonic: mnemonic,
        password: password,
        name: name,
        accountIndex: accountIndex);
  }

  factory BitcoinWalletBase.build(
      {@required String mnemonic,
      @required String password,
      @required String name,
      @required String dirPath,
      int accountIndex = 0}) {
    final walletPath = '$dirPath/$name';
    final eclient = ElectrumClient();
    final history = BitcoinTransactionHistory(
        eclient: eclient, dirPath: dirPath, password: password);

    return BitcoinWallet._internal(
        eclient: eclient,
        path: walletPath,
        mnemonic: mnemonic,
        password: password,
        accountIndex: accountIndex,
        transactionHistory: history);
  }

  BitcoinWalletBase._internal(
      {@required this.eclient,
      @required this.path,
      @required String password,
      int accountIndex = 0,
      this.transactionHistory,
      this.mnemonic}) {
    hd = bitcoin.HDWallet.fromSeed(bip39.mnemonicToSeed(mnemonic),
        network: bitcoin.bitcoin);
    _password = password;
    _accountIndex = accountIndex;
  }

  final BitcoinTransactionHistory transactionHistory;
  final String path;
  bitcoin.HDWallet hd;
  final ElectrumClient eclient;
  final String mnemonic;
  int _accountIndex;
  String _password;

  @override
  String get name => path.split('/').last ?? '';

  @override
  String get filename => hd.address;

  String get xpub => hd.base58;

  List<String> getAddresses() => _accountIndex == 0
      ? [address]
      : List<String>.generate(
          _accountIndex, (i) => _getAddress(hd: hd, index: i));

  Future<void> init() async {
    await transactionHistory.init();
  }

  Future<String> newAddress() async {
    _accountIndex += 1;
    final address = _getAddress(hd: hd, index: _accountIndex);
    await save();

    return address;
  }

  @override
  Future<void> startSync() async {}

  @override
  Future<void> connectToNode({@required Node node}) async {}

  @override
  Future<void> createTransaction(Object credentials) async {}

  @override
  Future<void> save() async => await write(
      path: path,
      password: _password,
      obj: {'mnemonic': mnemonic, 'account_index': _accountIndex.toString()});

  String _getAddress({bitcoin.HDWallet hd, int index}) => bitcoin
      .P2PKH(
          data: PaymentData(
              pubkey: Uint8List.fromList(hd.derive(index).pubKey.codeUnits)))
      .data
      .address;

  Future<Map<String, int>> _fetchBalances() async {
    final balances = await Future.wait(
        getAddresses().map((address) => eclient.getBalance(address: address)));
    final balance = balances.fold(<String, int>{}, (Map<String, int> acc, val) {
      acc['confirmed'] =
          (val['confirmed'] as int ?? 0) + (acc['confirmed'] ?? 0);
      acc['unconfirmed'] =
          (val['unconfirmed'] as int ?? 0) + (acc['unconfirmed'] ?? 0);

      return acc;
    });

    return balance;
  }
}
