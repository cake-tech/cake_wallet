import 'dart:convert';

import 'package:cake_wallet/src/screens/integrations/moonpay/services/moonpay_virtual_account_api.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:crypto/crypto.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';

part 'moonpay_virtual_account_view_model.g.dart';

class MoonPayVirtualAccountViewModel = MoonPayVirtualAccountViewModelBase
    with _$MoonPayVirtualAccountViewModel;

abstract class MoonPayVirtualAccountViewModelBase with Store {
  MoonPayVirtualAccountViewModelBase(
      {required this.moonPayVirtualAccountApi, required this.appStore});

  final MoonpayVirtualAccountApi moonPayVirtualAccountApi;
  final AppStore appStore;

  String createAccountUrl({
    String? theme,
    String? email,
    String? sourceCurrencyCode,
    String? destinationCurrencyCode,
  }) {
    try {
      final wallet = appStore.wallet;
      if (wallet == null) {
        throw StateError('No active wallet');
      }

      final externalCustomerId = this.buildExternalCustomerId(wallet);

      return moonPayVirtualAccountApi.buildCreateAccountUrl(
        walletAddress: wallet.walletAddresses.primaryAddress,
        walletAddressIsPartnerGenerated: true,
        externalCustomerId: externalCustomerId,
        theme: theme,
        email: email,
        sourceCurrencyCode: sourceCurrencyCode,
        destinationCurrencyCode: destinationCurrencyCode,
      );
    } catch (e, s) {
      // Keep logging lightweight; UI can decide how to react
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

  String buildExternalCustomerId(WalletBase wallet) {
    final raw = '${wallet.type}:${wallet.walletAddresses.primaryAddress}';
    final digest = sha256.convert(utf8.encode(raw)).toString();
    return 'cw_va_$digest';
  }
  /// Calls MoonPay Virtual Accounts API and returns raw details response
  Future<List<dynamic>> fetchVirtualAccountDetails({
    required String externalCustomerId,
  }) async {
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
