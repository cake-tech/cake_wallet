import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/node_list.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'commons.dart';

class MigrationV1 {
  static Future<void> run() async {
    final nodes = getIt.get<Box<Node>>();
    final sharedPreferences = getIt.get<SharedPreferences>();

    await sharedPreferences.setString(
        PreferencesKey.currentFiatCurrencyKey, FiatCurrency.usd.toString());
    await sharedPreferences.setInt(
        PreferencesKey.currentTransactionPriorityKeyLegacy,
        monero.getDefaultTransactionPriority().raw);
    await sharedPreferences.setInt(PreferencesKey.currentBalanceDisplayModeKey,
        BalanceDisplayMode.availableBalance.raw);
    await sharedPreferences.setBool('save_recipient_address', true);
    await resetToDefault(nodes);
    await changeMoneroCurrentNodeToDefault(
        sharedPreferences: sharedPreferences, nodes: nodes);
    await changeBitcoinCurrentElectrumServerToDefault(
        sharedPreferences: sharedPreferences, nodes: nodes);
    await changeLitecoinCurrentElectrumServerToDefault(
        sharedPreferences: sharedPreferences, nodes: nodes);
  }

  static Future resetToDefault(Box<Node> nodeSource) async {
    final moneroNodes = await loadDefaultNodes();
    final bitcoinElectrumServerList = await loadBitcoinElectrumServerList();
    final litecoinElectrumServerList = await loadLitecoinElectrumServerList();
    final nodes =
        moneroNodes + bitcoinElectrumServerList + litecoinElectrumServerList;

    await nodeSource.clear();
    await nodeSource.addAll(nodes);
  }

  static Future<void> changeBitcoinCurrentElectrumServerToDefault(
      {@required SharedPreferences sharedPreferences,
      @required Box<Node> nodes}) async {
    final server = getBitcoinDefaultElectrumServer(nodes: nodes);
    final serverId = server?.key as int ?? 0;

    await sharedPreferences.setInt('current_node_id_btc', serverId);
  }

  static Future<void> changeLitecoinCurrentElectrumServerToDefault(
      {@required SharedPreferences sharedPreferences,
      @required Box<Node> nodes}) async {
    final server = getLitecoinDefaultElectrumServer(nodes: nodes);
    final serverId = server?.key as int ?? 0;

    await sharedPreferences.setInt('current_node_id_ltc', serverId);
  }

  static Node getBitcoinDefaultElectrumServer({@required Box<Node> nodes}) {
    return nodes.values.firstWhere(
            (Node node) => node.uri.toString() == cakeWalletBitcoinElectrumUri,
            orElse: () => null) ??
        nodes.values.firstWhere((node) => node.type == WalletType.bitcoin,
            orElse: () => null);
  }

  static Node getLitecoinDefaultElectrumServer({@required Box<Node> nodes}) {
    return nodes.values.firstWhere(
            (Node node) => node.uri.toString() == cakeWalletLitecoinElectrumUri,
            orElse: () => null) ??
        nodes.values.firstWhere((node) => node.type == WalletType.litecoin,
            orElse: () => null);
  }
}
