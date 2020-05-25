import 'dart:async';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/monero/account.dart';
import 'package:cake_wallet/src/domain/monero/monero_wallet.dart';
import 'package:cake_wallet/src/domain/monero/subaddress.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'monero_wallet_store.g.dart';

class MoneroWalletStore = MoneroWalletStoreBase with _$MoneroWalletStore;

abstract class MoneroWalletStoreBase with Store {
  
}