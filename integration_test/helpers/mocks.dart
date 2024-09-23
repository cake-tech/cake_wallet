import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/wallet_list_store.dart';
import 'package:cake_wallet/view_model/link_view_model.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockAppStore extends Mock implements AppStore{}
class MockAuthService extends Mock implements AuthService{}
class MockSettingsStore  extends Mock implements SettingsStore {}
class MockAuthenticationStore extends Mock implements AuthenticationStore{}
class MockWalletListStore extends Mock implements WalletListStore{}



class MockLinkViewModel  extends Mock implements LinkViewModel {}

class MockHiveInterface extends Mock implements HiveInterface {}

class MockHiveBox extends Mock implements Box<dynamic> {}

class MockSecureStorage extends Mock implements SecureStorage{}