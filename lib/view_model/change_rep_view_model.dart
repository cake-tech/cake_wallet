import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_provider.dart';
import 'package:cake_wallet/buy/wyre/wyre_buy_provider.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/buy/buy_item.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';

part 'change_rep_view_model.g.dart';

class ChangeRepViewModel = ChangeRepViewModelBase with _$ChangeRepViewModel;

abstract class ChangeRepViewModelBase with Store {
  ChangeRepViewModelBase() {}

  // final WalletBase wallet;
}
