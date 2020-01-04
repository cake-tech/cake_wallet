import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/screens/seed/seed_page.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/stores/wallet_seed/wallet_seed_store.dart';

Widget createSeedPage(
          {@required SettingsStore settingsStore,
          @required WalletService walletService,
          @required void Function() callback}) =>
      Provider(
          create: (_) => WalletSeedStore(walletService: walletService),
          child: SeedPage(onCloseCallback: callback));