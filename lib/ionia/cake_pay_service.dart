import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/ionia/cake_pay_api.dart';
import 'package:cake_wallet/ionia/cake_pay_card.dart';
import 'package:cake_wallet/ionia/cake_pay_order.dart';
import 'package:cake_wallet/ionia/cake_pay_vendor.dart';
import 'package:cake_wallet/ionia/ionia_category.dart';
import 'package:cake_wallet/ionia/ionia_virtual_card.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CakePayService {
  CakePayService(this.secureStorage, this.cakePayApi);

  static const cakePayEmailStorageKey = 'cake_pay_email';
  static const cakePayUsernameStorageKey = 'cake_pay_username';
  static const cakePayUserTokenKey = 'cake_pay_user_token';

  static String get testCakePayApiKey => secrets.testCakePayApiKey;

  static String get cakePayApiKey => secrets.cakePayApiKey;

  static String get CSRFToken => secrets.CSRFToken;

  static String get authorization => secrets.authorization;

  final FlutterSecureStorage secureStorage;
  final CakePayApi cakePayApi;

  /// Get Available Countries
  Future<List<String>> getCountries() async =>
      await cakePayApi.getCountries(CSRFToken: CSRFToken, authorization: authorization);

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
        CSRFToken: CSRFToken,
        authorization: authorization,
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
    final userName = await cakePayApi.authenticateUser(email: email, apiKey: testCakePayApiKey);
    await secureStorage.write(key: cakePayEmailStorageKey, value: userName);
    await secureStorage.write(key: cakePayUsernameStorageKey, value: userName);
  }

  /// Verify email
  Future<void> verifyEmail(String code) async {
    final email = (await secureStorage.read(key: cakePayEmailStorageKey))!;
    final credentials =
        await cakePayApi.verifyEmail(email: email, code: code, apiKey: testCakePayApiKey);
    await secureStorage.write(key: cakePayUserTokenKey, value: credentials.token);
    await secureStorage.write(key: cakePayUsernameStorageKey, value: credentials.username);
  }

  Future<String> getUserEmail() async {
    return (await secureStorage.read(key: cakePayEmailStorageKey))!;
  }

  /// Check is user logged
  Future<bool> isLogged() async {
    final username = await secureStorage.read(key: cakePayUsernameStorageKey) ?? '';
    final password = await secureStorage.read(key: cakePayUserTokenKey) ?? '';
    return username.isNotEmpty && password.isNotEmpty;
  }

  /// Logout
  Future<void> logout(String email) async {
    await secureStorage.delete(key: cakePayUsernameStorageKey);
    await secureStorage.delete(key: cakePayUserTokenKey);
    await cakePayApi.logoutUser(email: email, apiKey: testCakePayApiKey);
  }

  // Create virtual card

  Future<CakePayVirtualCard> createCard() async {
    final username = (await secureStorage.read(key: cakePayUsernameStorageKey))!;
    final password = (await secureStorage.read(key: cakePayUserTokenKey))!;
    return cakePayApi.createCard(
        username: username, password: password, clientId: testCakePayApiKey);
  }

  // Get Merchants By Filter

  Future<List<IoniaMerchant>> getMerchantsByFilter(
      {String? search, List<IoniaCategory>? categories, int merchantFilterType = 0}) async {
    //final username = (await secureStorage.read(key: ioniaUsernameStorageKey))!;
    //final password = (await secureStorage.read(key: ioniaPasswordStorageKey))!;
    return cakePayApi.getMerchantsByFilter(
        search: search, categories: categories, merchantFilterType: merchantFilterType);
  }

  /// Purchase Gift Card
  Future<CakePayOrder> createOrder(
      {required int cardId, required String price, required int quantity}) async {
    final userEmail = (await secureStorage.read(key: cakePayEmailStorageKey))!;
    final token = (await secureStorage.read(key: cakePayUserTokenKey))!;
    return await cakePayApi.createOrder(
        apiKey: testCakePayApiKey,
        cardId: cardId,
        price: price,
        quantity: quantity,
        token: token,
        userEmail: userEmail);
  }

  ///Simulate Purchase Gift Card
  Future<void> simulatePayment({required String orderId}) async => await cakePayApi.simulatePayment(
      CSRFToken: CSRFToken, authorization: authorization, orderId: orderId);

  // Get Current User Gift Card Summaries

  Future<List<IoniaGiftCard>> getCurrentUserGiftCardSummaries() async {
    final username = (await secureStorage.read(key: cakePayUsernameStorageKey))!;
    final password = (await secureStorage.read(key: cakePayUserTokenKey))!;
    return cakePayApi.getCurrentUserGiftCardSummaries(
        username: username, password: password, clientId: testCakePayApiKey);
  }

  // Charge Gift Card

  Future<void> chargeGiftCard({required int giftCardId, required double amount}) async {
    final username = (await secureStorage.read(key: cakePayUsernameStorageKey))!;
    final password = (await secureStorage.read(key: cakePayUserTokenKey))!;
    await cakePayApi.chargeGiftCard(
        username: username,
        password: password,
        clientId: testCakePayApiKey,
        giftCardId: giftCardId,
        amount: amount);
  }

  // Redeem

  Future<void> redeem({required int giftCardId, required double amount}) async {
    await chargeGiftCard(giftCardId: giftCardId, amount: amount);
  }

  // Get Gift Card

  Future<IoniaGiftCard> getGiftCard({required int id}) async {
    final username = (await secureStorage.read(key: cakePayUsernameStorageKey))!;
    final password = (await secureStorage.read(key: cakePayUserTokenKey))!;
    return cakePayApi.getGiftCard(
        username: username, password: password, clientId: testCakePayApiKey, id: id);
  }

  // Payment Status

  Future<int> getPaymentStatus({required String orderId, required String paymentId}) async {
    final username = (await secureStorage.read(key: cakePayUsernameStorageKey))!;
    final password = (await secureStorage.read(key: cakePayUserTokenKey))!;
    return cakePayApi.getPaymentStatus(
        username: username,
        password: password,
        clientId: testCakePayApiKey,
        orderId: orderId,
        paymentId: paymentId);
  }
}
