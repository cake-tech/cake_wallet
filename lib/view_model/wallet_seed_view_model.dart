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

  /// The Regex split the words based on any whitespace character.
  ///
  /// Either standard ASCII space (U+0020) or the full-width space character (U+3000) used by the Japanese.
  List<String> get seedSplit => seed.split(RegExp(r'\s+'));

  int get columnCount => seedSplit.length <= 16 ? 2 : 3;
}
