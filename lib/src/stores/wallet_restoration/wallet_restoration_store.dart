import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/src/domain/services/wallet_list_service.dart';
import 'package:cake_wallet/src/domain/common/mnemotic_item.dart';
import 'package:cake_wallet/src/stores/wallet_restoration/wallet_restoration_state.dart';
import 'package:cake_wallet/src/stores/authentication/authentication_store.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'wallet_restoration_store.g.dart';

class WalletRestorationStore = WalleRestorationStoreBase
    with _$WalletRestorationStore;

abstract class WalleRestorationStoreBase with Store {
  WalleRestorationStoreBase(
      {this.seed,
      @required this.authStore,
      @required this.walletListService,
      @required this.sharedPreferences}) {
    state = WalletRestorationStateInitial();
  }

  final AuthenticationStore authStore;
  final WalletListService walletListService;
  final SharedPreferences sharedPreferences;

  @observable
  WalletRestorationState state;

  @observable
  String errorMessage;

  @observable
  bool isValid;

  @observable
  List<MnemoticItem> seed;

  @action
  Future restoreFromSeed({String name, String seed, int restoreHeight}) async {
    state = WalletRestorationStateInitial();
    final _seed = seed ?? _seedText();

    try {
      state = WalletIsRestoring();
      await walletListService.restoreFromSeed(name, _seed, restoreHeight);
      authStore.restored();
      state = WalletRestoredSuccessfully();
    } catch (e) {
      state = WalletRestorationFailure(error: e.toString());
    }
  }

  @action
  Future restoreFromKeys(
      {String name,
      String address,
      String viewKey,
      String spendKey,
      int restoreHeight}) async {
    state = WalletRestorationStateInitial();

    try {
      state = WalletIsRestoring();
      await walletListService.restoreFromKeys(
          name, restoreHeight, address, viewKey, spendKey);
      authStore.restored();
      state = WalletRestoredSuccessfully();
    } catch (e) {
      state = WalletRestorationFailure(error: e.toString());
    }
  }

  @action
  void setSeed(List<MnemoticItem> seed) {
    this.seed = seed;
  }

  @action
  void validateSeed(List<MnemoticItem> seed) {
    final _seed = seed != null ? seed : this.seed;
    bool isValid = _seed != null ? _seed.length == 25 : false;

    if (!isValid) {
      errorMessage = S.current.wallet_restoration_store_incorrect_seed_length;
      this.isValid = isValid;
      return;
    }

    for (final item in _seed) {
      if (!item.isCorrect()) {
        isValid = false;
        break;
      }
    }

    if (isValid) {
      errorMessage = null;
    }

    this.isValid = isValid;
    return;
  }

  String _seedText() {
    return seed.fold('', (acc, item) => acc + ' ' + item.toString());
  }

  void validateWalletName(String value) {
    const pattern = '^[a-zA-Z0-9_]{1,15}\$';
    final regExp = RegExp(pattern);
    isValid = regExp.hasMatch(value);
    errorMessage = isValid ? null : S.current.error_text_wallet_name;
  }

  void validateAddress(String value, {CryptoCurrency cryptoCurrency}) {
    // XMR (95), BTC (34), ETH (42), LTC (34), BCH (42), DASH (34)
    const pattern = '^[0-9a-zA-Z]{95}\$|^[0-9a-zA-Z]{34}\$|^[0-9a-zA-Z]{42}\$';
    final regExp = RegExp(pattern);
    isValid = regExp.hasMatch(value);

    if (isValid && cryptoCurrency != null) {
      switch (cryptoCurrency.toString()) {
        case 'XMR':
          isValid = (value.length == 95);
          break;
        case 'BTC':
          isValid = (value.length == 34);
          break;
        case 'ETH':
          isValid = (value.length == 42);
          break;
        case 'LTC':
          isValid = (value.length == 34);
          break;
        case 'BCH':
          isValid = (value.length == 42);
          break;
        case 'DASH':
          isValid = (value.length == 34);
      }
    }

    errorMessage = isValid ? null : S.current.error_text_address;
  }

  void validateKeys(String value) {
    const pattern = '^[A-Fa-f0-9]{64}\$';
    final regExp = RegExp(pattern);
    isValid = regExp.hasMatch(value);
    errorMessage = isValid ? null : S.current.error_text_keys;
  }
}
