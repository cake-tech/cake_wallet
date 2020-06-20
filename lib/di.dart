import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/dashboard/dashboard_page.dart';
import 'package:cake_wallet/src/screens/receive/receive_page.dart';
import 'package:cake_wallet/src/screens/subaddress/address_edit_or_create_page.dart';
import 'package:cake_wallet/view_model/address_list/address_edit_or_create_view_model.dart';
import 'package:cake_wallet/view_model/auth_view_model.dart';
import 'package:cake_wallet/view_model/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/address_list/address_list_view_model.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cake_wallet/view_model/wallet_restoration_from_seed_vm.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';
import 'package:cake_wallet/store/authentication_store.dart';

final getIt = GetIt.instance;

ReactionDisposer _onCurrentWalletChangeReaction;

void setup() {
  getIt.registerSingleton(AuthenticationStore());
  getIt.registerSingleton<AppStore>(
      AppStore(authenticationStore: getIt.get<AuthenticationStore>()));
  getIt.registerSingleton<FlutterSecureStorage>(FlutterSecureStorage());
  getIt.registerSingletonAsync<SharedPreferences>(
      () => SharedPreferences.getInstance());
  getIt.registerFactoryParam<WalletCreationService, WalletType, void>(
      (type, _) => WalletCreationService(
          initialType: type,
          appStore: getIt.get<AppStore>(),
          secureStorage: getIt.get<FlutterSecureStorage>(),
          sharedPreferences: getIt.get<SharedPreferences>()));

  getIt.registerFactoryParam<WalletNewVM, WalletType, void>((type, _) =>
      WalletNewVM(getIt.get<WalletCreationService>(param1: type), type: type));

  getIt
      .registerFactoryParam<WalletRestorationFromSeedVM, List, void>((args, _) {
    final type = args.first as WalletType;
    final language = args[1] as String;
    final mnemonic = args[2] as String;

    return WalletRestorationFromSeedVM(
        getIt.get<WalletCreationService>(param1: type),
        type: type,
        language: language,
        seed: mnemonic);
  });

  getIt.registerFactory<AddressListViewModel>(
      () => AddressListViewModel(wallet: getIt.get<AppStore>().wallet));

  getIt.registerFactory(
      () => DashboardViewModel(appStore: getIt.get<AppStore>()));

  getIt.registerFactory<AuthService>(() => AuthService(
      secureStorage: getIt.get<FlutterSecureStorage>(),
      sharedPreferences: getIt.get<SharedPreferences>()));

  getIt.registerFactory<AuthViewModel>(() => AuthViewModel(
      authService: getIt.get<AuthService>(),
      sharedPreferences: getIt.get<SharedPreferences>()));

  getIt.registerFactory<AuthPage>(() => AuthPage(
      authViewModel: getIt.get<AuthViewModel>(),
      onAuthenticationFinished: (isAuthenticated, __) {
        if (isAuthenticated) {
          getIt.get<AuthenticationStore>().allowed();
        }
      },
      closable: false));

  getIt.registerFactory<DashboardPage>(() => DashboardPage(
        walletViewModel: getIt.get<DashboardViewModel>(),
      ));

  getIt.registerFactory<ReceivePage>(() =>
      ReceivePage(addressListViewModel: getIt.get<AddressListViewModel>()));

  getIt.registerFactoryParam<AddressEditOrCreateViewModel, dynamic, void>(
      (dynamic item, _) => AddressEditOrCreateViewModel(
          wallet: getIt.get<AppStore>().wallet, item: item));

  getIt.registerFactoryParam<AddressEditOrCreatePage, dynamic, void>(
      (dynamic item, _) => AddressEditOrCreatePage(
          addressEditOrCreateViewModel:
              getIt.get<AddressEditOrCreateViewModel>(param1: item)));

  final appStore = getIt.get<AppStore>();

  _onCurrentWalletChangeReaction ??=
      reaction((_) => appStore.wallet, (WalletBase wallet) async {
    print('Wallet name ${wallet.name}');
    await getIt
        .get<SharedPreferences>()
        .setString('current_wallet_name', wallet.name);
  });
}
