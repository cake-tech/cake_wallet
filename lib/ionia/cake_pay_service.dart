import 'package:cake_wallet/ionia/cake_pay_vendor.dart';
import 'package:cake_wallet/ionia/ionia_order.dart';
import 'package:cake_wallet/ionia/ionia_virtual_card.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/ionia/cake_pay_api.dart';
import 'package:cake_wallet/ionia/cake_pay_card.dart';
import 'package:cake_wallet/ionia/ionia_category.dart';

class CakePayService {
  CakePayService(this.secureStorage, this.cakePayApi);

  static const cakePayEmailStorageKey = 'cake_pay_email';
  static const cakePayUsernameStorageKey = 'cake_pay_username';
  static const cakePayUserTokenKey = 'cake_pay_user_token';

  static String get cakePayApiKey => secrets.testCakePayApiKey;

  final FlutterSecureStorage secureStorage;
  final CakePayApi cakePayApi;

  /// Get Available Countries
  Future<List<String>> getCountries() async => await cakePayApi.getCountries();

  /// Get Vendors
  Future<List<CakePayVendor>> getVendors({required int page, required String country}) async {
    final result = await cakePayApi.getVendors(page: page, country: country);
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
    await cakePayApi.logoutUser(email: email, apiKey: cakePayApiKey);
  }

  // Create virtual card

  Future<CakePayVirtualCard> createCard() async {
    final username = (await secureStorage.read(key: cakePayUsernameStorageKey))!;
    final password = (await secureStorage.read(key: cakePayUserTokenKey))!;
    return cakePayApi.createCard(username: username, password: password, clientId: cakePayApiKey);
  }

  // Get Merchants By Filter

  Future<List<IoniaMerchant>> getMerchantsByFilter(
      {String? search, List<IoniaCategory>? categories, int merchantFilterType = 0}) async {
    //final username = (await secureStorage.read(key: ioniaUsernameStorageKey))!;
    //final password = (await secureStorage.read(key: ioniaPasswordStorageKey))!;
    return cakePayApi.getMerchantsByFilter(
        search: search, categories: categories, merchantFilterType: merchantFilterType);
  }

  // Purchase Gift Card

  Future<IoniaOrder> purchaseGiftCard(
      {required String merchId, required double amount, required String currency}) async {
    final username = (await secureStorage.read(key: cakePayUsernameStorageKey))!;
    final password = (await secureStorage.read(key: cakePayUserTokenKey))!;
    final deviceId = '';
    return cakePayApi.purchaseGiftCard(
        requestedUUID: deviceId,
        merchId: merchId,
        amount: amount,
        currency: currency,
        username: username,
        password: password,
        clientId: cakePayApiKey);
  }

  // Get Current User Gift Card Summaries

  Future<List<IoniaGiftCard>> getCurrentUserGiftCardSummaries() async {
    final username = (await secureStorage.read(key: cakePayUsernameStorageKey))!;
    final password = (await secureStorage.read(key: cakePayUserTokenKey))!;
    return cakePayApi.getCurrentUserGiftCardSummaries(
        username: username, password: password, clientId: cakePayApiKey);
  }

  // Charge Gift Card

  Future<void> chargeGiftCard({required int giftCardId, required double amount}) async {
    final username = (await secureStorage.read(key: cakePayUsernameStorageKey))!;
    final password = (await secureStorage.read(key: cakePayUserTokenKey))!;
    await cakePayApi.chargeGiftCard(
        username: username,
        password: password,
        clientId: cakePayApiKey,
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
        username: username, password: password, clientId: cakePayApiKey, id: id);
  }

  // Payment Status

  Future<int> getPaymentStatus({required String orderId, required String paymentId}) async {
    final username = (await secureStorage.read(key: cakePayUsernameStorageKey))!;
    final password = (await secureStorage.read(key: cakePayUserTokenKey))!;
    return cakePayApi.getPaymentStatus(
        username: username,
        password: password,
        clientId: cakePayApiKey,
        orderId: orderId,
        paymentId: paymentId);
  }
}
