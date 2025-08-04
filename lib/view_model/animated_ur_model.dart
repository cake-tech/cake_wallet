import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';

class AnimatedURModel with Store {
 AnimatedURModel(this.appStore)
      : wallet = appStore.wallet!;
  final AppStore appStore;
  final WalletBase wallet;
}