import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'haven_removal_view_model.g.dart';

class HavenRemovalViewModel = HavenRemovalViewModelBase with _$HavenRemovalViewModel;

abstract class HavenRemovalViewModelBase with Store {
  HavenRemovalViewModelBase(
      {required this.appStore, required this.walletInfoSource, required this.walletLoadingService});

  final AppStore appStore;
  final Box<WalletInfo> walletInfoSource;
  final WalletLoadingService walletLoadingService;

  Future<void> onSeedsCopiedConfirmed() async {
    if (walletInfoSource.length == 1) {
      _navigateToWelcomePage();
      return;
    }

    final walletInfo = _getFirstNonHavenWallet();

    final wallet = await _loadWallet(walletInfo.type, walletInfo.name);

    _changeWallet(wallet);

    await _navigateToDashboardPage();
  }

  WalletInfo _getFirstNonHavenWallet() {
    return walletInfoSource.values.firstWhere((element) => element.type != WalletType.haven);
  }

  Future<WalletBase> _loadWallet(WalletType type, String walletName) async {
    final wallet = await walletLoadingService.load(type, walletName);

    return wallet;
  }

  void _changeWallet(WalletBase wallet) {
    appStore.changeCurrentWallet(wallet);
  }

  Future<void> _navigateToDashboardPage() async {
    await navigatorKey.currentState!.pushNamedAndRemoveUntil(Routes.dashboard, (route) => false);
    return;
  }

  Future<void> _navigateToWelcomePage() async {
    await navigatorKey.currentState!.pushNamedAndRemoveUntil(Routes.welcome, (route) => false);
    return;
  }
}
