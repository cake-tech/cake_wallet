import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/src/domain/monero/transaction_description.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/screens/dashboard/dashboard_page.dart';
import 'package:cake_wallet/src/stores/action_list/action_list_store.dart';
import 'package:cake_wallet/src/stores/action_list/trade_filter_store.dart';
import 'package:cake_wallet/src/stores/action_list/transaction_filter_store.dart';
import 'package:cake_wallet/src/stores/price/price_store.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';

Widget createDashboardPage(
        {@required WalletService walletService,
        @required PriceStore priceStore,
        @required Box<TransactionDescription> transactionDescriptions,
        @required SettingsStore settingsStore,
        @required Box<Trade> trades,
        @required WalletStore walletStore}) =>
    Provider(
        create: (_) => ActionListStore(
            walletService: walletService,
            settingsStore: settingsStore,
            priceStore: priceStore,
            tradesSource: trades,
            transactionFilterStore: TransactionFilterStore(),
            tradeFilterStore: TradeFilterStore(walletStore: walletStore),
            transactionDescriptions: transactionDescriptions),
        child: DashboardPage());
