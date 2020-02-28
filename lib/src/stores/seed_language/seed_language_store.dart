import 'package:mobx/mobx.dart';
import 'package:cake_wallet/routes.dart';

part 'seed_language_store.g.dart';

const List<String> seedLanguages = [
  'English',
  'Chinese (simplified)',
  'Dutch',
  'German',
  'Japanese',
  'Portuguese',
  'Russian',
  'Spanish'
];

class SeedLanguageStore = SeedLanguageStoreBase with _$SeedLanguageStore;

abstract class SeedLanguageStoreBase with Store {
  SeedLanguageStoreBase() {
    selectedSeedLanguage = seedLanguages[0];
    currentRoute = Routes.newWallet;
  }

  @observable
  String selectedSeedLanguage;

  String currentRoute;

  @action
  void setSelectedSeedLanguage(String seedLanguage) {
    selectedSeedLanguage = seedLanguage;
  }

  void setCurrentRoute(String route) {
    currentRoute = route;
  }
}