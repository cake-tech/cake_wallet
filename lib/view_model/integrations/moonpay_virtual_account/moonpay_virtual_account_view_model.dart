import 'dart:convert';

import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/src/screens/integrations/moonpay/services/moonpay_virtual_account_api.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:crypto/crypto.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'moonpay_virtual_account_view_model.g.dart';

class MoonPayVirtualAccountViewModel = MoonPayVirtualAccountViewModelBase
    with _$MoonPayVirtualAccountViewModel;

abstract class MoonPayVirtualAccountViewModelBase with Store {
  MoonPayVirtualAccountViewModelBase({
    required this.moonPayVirtualAccountApi,
    required this.appStore,
    required this.settingsStore,
    required this.walletList,
  })  : selectedFiatCurrency = availableFiatOptions.firstWhere(
            (fiat) => fiat == settingsStore.fiatCurrency,
            orElse: () => availableFiatOptions.last),
        selectedWalletInfo = appStore.wallet?.walletInfo,
        selectedStablecoinKey = availableStablecoinsByGroup.entries
            .firstWhere((entry) => entry.value.containsKey(appStore.wallet?.type),
                orElse: () => availableStablecoinsByGroup.entries.first)
            .key,
        selectedWalletType = appStore.wallet?.type;

  final externalCustomerId = 'cw_va_123456789';
  final MoonpayVirtualAccountApi moonPayVirtualAccountApi;
  final AppStore appStore;
  final SettingsStore settingsStore;
  final List<WalletInfo> walletList;

  static const availableFiatOptions = [
    FiatCurrency.usd,
    FiatCurrency.eur,
    FiatCurrency.gbp,
  ];

  static const availableStablecoinsByGroup = {
    'USDC': {
      WalletType.ethereum: CryptoCurrency.usdc,
      WalletType.polygon: CryptoCurrency.usdcpoly,
      WalletType.solana: CryptoCurrency.usdcsol,
      WalletType.arbitrum: CryptoCurrency.usdcArb,
    },
    'USDT': {
      WalletType.ethereum: CryptoCurrency.usdterc20,
      WalletType.polygon: CryptoCurrency.usdtPoly,
      WalletType.solana: CryptoCurrency.usdtSol,
      WalletType.arbitrum: CryptoCurrency.usdtArb,
    }
  };

  WalletInfo? selectedWalletInfo;
  FiatCurrency selectedFiatCurrency;
  String? selectedStablecoinKey;
  WalletType? selectedWalletType;

  List<CryptoCurrency> get allAvailableStablecoins =>
      availableStablecoinsByGroup.values
          .map((group) => group.values.first)
          .toList();

  CryptoCurrency? get selectedStablecoinForKeyAndWalletType {
    if (selectedStablecoinKey == null || selectedWalletType == null) {
      return null;
    }
    final mapping = availableStablecoinsByGroup[selectedStablecoinKey!];
    if (mapping == null) {
      return null;
    }
    return mapping[selectedWalletType!];
  }

  List<WalletType> get availableWalletTypesByStablecoinKey {
    if (selectedStablecoinKey == null) {
      return [];
    }
    final mapping = availableStablecoinsByGroup[selectedStablecoinKey!];
    if (mapping == null) {
      return [];
    }
    return mapping.keys.toList();
  }

  List<WalletInfo> get availableWalletsForSelectedStablecoin {
    if (selectedStablecoinKey == null || selectedWalletType == null) {
      return [];
    }

    return walletList.where((wallet) => wallet.type == selectedWalletType).toList();
  }

  void selectFiat(FiatCurrency fiat) => selectedFiatCurrency = fiat;

  void selectStablecoinKey(CryptoCurrency stablecoin) => selectedStablecoinKey = stablecoin.title;

  void selectNetwork(WalletType walletType) => selectedWalletType = walletType;

  void selectWallet(WalletInfo walletInfo) => selectedWalletInfo = walletInfo;


  String createAccountUrl({
    String? theme,
    String? email,
  }) {
    try {
      final wallet = selectedWalletInfo;
      if (wallet == null) {
        throw StateError('No active wallet');
      }

      //final externalCustomerId = this.buildExternalCustomerId(wallet);

      return moonPayVirtualAccountApi.buildCreateAccountUrl(
          walletAddress: wallet.address,
          walletAddressIsPartnerGenerated: true,
          externalCustomerId: externalCustomerId, //externalCustomerId,
          theme: theme,
          email: email,
          sourceCurrencyCode: selectedFiatCurrency.name,
          destinationCurrencyCode: selectedStablecoinKey);
    } catch (e, s) {
      print(s);
      rethrow;
    }
  }

  String accountAccessUrl({String? theme}) {
    try {
      return moonPayVirtualAccountApi.buildAccountAccessUrl(theme: theme);
    } catch (e, s) {
      print(s);
      rethrow;
    }
  }

  String buildExternalCustomerId(WalletInfo wallet) {
    final raw = '${wallet.type}:${wallet.address}';
    final digest = sha256.convert(utf8.encode(raw)).toString();
    return 'cw_va_$digest';
  }

  /// Calls MoonPay Virtual Accounts API and returns raw details response
  Future<List<dynamic>> fetchVirtualAccountDetails() async {
    try {
      final response = await moonPayVirtualAccountApi.fetchVirtualAccountDetails(
        externalCustomerId: externalCustomerId,
      );
      return response;
    } catch (e, s) {
      print(s);
      rethrow;
    }
  }
}
