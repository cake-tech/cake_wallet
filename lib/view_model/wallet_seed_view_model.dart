import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';

part 'wallet_seed_view_model.g.dart';

class WalletSeedViewModel = WalletSeedViewModelBase with _$WalletSeedViewModel;

abstract class WalletSeedViewModelBase with Store {
  WalletSeedViewModelBase(WalletBase wallet)
      : name = wallet.name,
        seed = wallet.seed!;

  @observable
  String name;

  @observable
  String seed;
}
