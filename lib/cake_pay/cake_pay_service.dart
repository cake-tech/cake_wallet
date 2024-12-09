import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/cake_pay/cake_pay_api.dart';
import 'package:cake_wallet/cake_pay/cake_pay_order.dart';
import 'package:cake_wallet/cake_pay/cake_pay_vendor.dart';
import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/country.dart';

class CakePayService {
  CakePayService(this.secureStorage, this.cakePayApi);

  static const cakePayEmailStorageKey = 'cake_pay_email';
  static const cakePayUsernameStorageKey = 'cake_pay_username';
  static const cakePayUserTokenKey = 'cake_pay_user_token';

  static String get testCakePayApiKey => secrets.testCakePayApiKey;

  static String get cakePayApiKey => secrets.cakePayApiKey;

  static String get CSRFToken => secrets.CSRFToken;

  static String get authorization => secrets.authorization;

  final SecureStorage secureStorage;
  final CakePayApi cakePayApi;

  /// Get Available Countries
  Future<List<Country>> getCountries() async =>
      await cakePayApi.getCountries(apiKey: cakePayApiKey);

  /// Get Vendors
  Future<List<CakePayVendor>> getVendors({
    int? page,
    String? country,
    String? countryCode,
    String? search,
    List<String>? vendorIds,
    bool? giftCards,
    bool? prepaidCards,
    bool? onDemand,
    bool? custom,
  }) async {
    final result = await cakePayApi.getVendors(
        apiKey: cakePayApiKey,
        page: page,
        country: country,
        countryCode: countryCode,
        search: search,
        vendorIds: vendorIds,
        giftCards: giftCards,
        prepaidCards: prepaidCards,
        onDemand: onDemand,
        custom: custom);
    return result;
  }

  /// LogIn
  Future<void> logIn(String email) async {
    final userName = await cakePayApi.authenticateUser(email: email, apiKey: cakePayApiKey);
    await secureStorage.write(key: cakePayEmailStorageKey, value: userName);
    await secureStorage.write(key: cakePayUsernameStorageKey, value: userName);
  }

  /// Verify email
  Future<void> verifyEmail(String code) async {
    final email = (await secureStorage.read(key: cakePayEmailStorageKey))!;
    final credentials =
        await cakePayApi.verifyEmail(email: email, code: code, apiKey: cakePayApiKey);
    await secureStorage.write(key: cakePayUserTokenKey, value: credentials.token);
    await secureStorage.write(key: cakePayUsernameStorageKey, value: credentials.username);
  }

  Future<String?> getUserEmail() async {
    return (await secureStorage.read(key: cakePayEmailStorageKey));
  }

  /// Check is user logged
  Future<bool> isLogged() async {
    final username = await secureStorage.read(key: cakePayUsernameStorageKey) ?? '';
    final password = await secureStorage.read(key: cakePayUserTokenKey) ?? '';
    return username.isNotEmpty && password.isNotEmpty;
  }

  /// Logout
  Future<void> logout([String? email]) async {
    await secureStorage.delete(key: cakePayUsernameStorageKey);
    await secureStorage.delete(key: cakePayUserTokenKey);
    if (email != null) {
      await cakePayApi.logoutUser(email: email, apiKey: cakePayApiKey);
    }
  }

  /// Purchase Gift Card
  Future<CakePayOrder> createOrder(
      {required int cardId, required String price, required int quantity}) async {
    final userEmail = (await secureStorage.read(key: cakePayEmailStorageKey))!;
    final token = (await secureStorage.read(key: cakePayUserTokenKey))!;
    return await cakePayApi.createOrder(
        apiKey: cakePayApiKey,
        cardId: cardId,
        price: price,
        quantity: quantity,
        token: token,
        userEmail: userEmail);
  }

  ///Simulate Purchase Gift Card
  Future<void> simulatePayment({required String orderId}) async => await cakePayApi.simulatePayment(
      CSRFToken: CSRFToken, authorization: authorization, orderId: orderId);
}
