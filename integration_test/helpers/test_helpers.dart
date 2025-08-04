import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/wallet_list_store.dart';
import 'package:cake_wallet/view_model/link_view_model.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

class TestHelpers {
  static void setup() {
    // Fallback values can also be declared here
    registerDependencies();
  }

  static void registerDependencies() {
    getAndRegisterAppStore();
    getAndRegisterAuthService();
    getAndRegisterSettingsStore();
    getAndRegisterAuthenticationStore();
    getAndRegisterWalletListStore();

    getAndRegisterLinkViewModel();
    getAndRegisterSecureStorage();
    getAndRegisterHiveInterface();
  }

  static MockSettingsStore getAndRegisterSettingsStore() {
    _removeRegistrationIfExists<SettingsStore>();
    final service = MockSettingsStore();
    getIt.registerSingleton<SettingsStore>(service);
    return service;
  }

  static MockAppStore getAndRegisterAppStore() {
    _removeRegistrationIfExists<AppStore>();
    final service = MockAppStore();
    final settingsStore = getAndRegisterSettingsStore();

    when(() => service.settingsStore).thenAnswer((invocation) => settingsStore);
    getIt.registerSingleton<AppStore>(service);
    return service;
  }

  static MockAuthService getAndRegisterAuthService() {
    _removeRegistrationIfExists<AuthService>();
    final service = MockAuthService();
    getIt.registerSingleton<AuthService>(service);
    return service;
  }

  static MockAuthenticationStore getAndRegisterAuthenticationStore() {
    _removeRegistrationIfExists<AuthenticationStore>();
    final service = MockAuthenticationStore();
    when(() => service.state).thenReturn(AuthenticationState.uninitialized);
    getIt.registerSingleton<AuthenticationStore>(service);
    return service;
  }

  static MockWalletListStore getAndRegisterWalletListStore() {
    _removeRegistrationIfExists<WalletListStore>();
    final service = MockWalletListStore();
    getIt.registerSingleton<WalletListStore>(service);
    return service;
  }

  static MockLinkViewModel getAndRegisterLinkViewModel() {
    _removeRegistrationIfExists<LinkViewModel>();
    final service = MockLinkViewModel();
    getIt.registerSingleton<LinkViewModel>(service);
    return service;
  }

  static MockHiveInterface getAndRegisterHiveInterface() {
    _removeRegistrationIfExists<HiveInterface>();
    final service = MockHiveInterface();
    getIt.registerSingleton<HiveInterface>(service);
    return service;
  }

  static MockSecureStorage getAndRegisterSecureStorage() {
    _removeRegistrationIfExists<SecureStorage>();
    final service = MockSecureStorage();
    getIt.registerSingleton<SecureStorage>(service);
    return service;
  }

  static void _removeRegistrationIfExists<T extends Object>() {
    if (getIt.isRegistered<T>()) {
      getIt.unregister<T>();
    }
  }

  static void tearDown() => getIt.reset();
}
