import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/ionia/ionia_order.dart';
import 'package:cake_wallet/ionia/ionia_virtual_card.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/ionia/ionia_api.dart';
import 'package:cake_wallet/ionia/ionia_gift_card.dart';
import 'package:cake_wallet/ionia/ionia_category.dart';

class IoniaService {
	IoniaService(this.secureStorage, this.ioniaApi);

	static const ioniaEmailStorageKey = 'ionia_email';
	static const ioniaUsernameStorageKey = 'ionia_username';
	static const ioniaPasswordStorageKey = 'ionia_password';

	static String get clientId => secrets.ioniaClientId;

	final FlutterSecureStorage secureStorage;
	final IoniaApi ioniaApi;

	// Create user

	Future<void> createUser(String email) async {
		final username = await ioniaApi.createUser(email, clientId: clientId);
		await secureStorage.write(key: ioniaEmailStorageKey, value: email);
		await secureStorage.write(key: ioniaUsernameStorageKey, value: username);
	}

	// Verify email

	Future<void> verifyEmail(String code) async {
		final email = (await secureStorage.read(key: ioniaEmailStorageKey))!;
		final credentials = await ioniaApi.verifyEmail(email: email, code: code, clientId: clientId);
		await secureStorage.write(key: ioniaPasswordStorageKey, value: credentials.password);
		await secureStorage.write(key: ioniaUsernameStorageKey, value: credentials.username);
	}

	// Sign In

	Future<void> signIn(String email) async {
		await ioniaApi.signIn(email, clientId: clientId);
		await secureStorage.write(key: ioniaEmailStorageKey, value: email);
	}

	Future<String> getUserEmail() async {
		return (await secureStorage.read(key: ioniaEmailStorageKey))!;
	}

	// Check is user logined

	Future<bool> isLogined() async {
		final username = await secureStorage.read(key: ioniaUsernameStorageKey) ?? '';
		final password = await secureStorage.read(key: ioniaPasswordStorageKey) ?? '';
		return username.isNotEmpty && password.isNotEmpty;
	}

	// Logout

	Future<void> logout() async {
		await secureStorage.delete(key: ioniaUsernameStorageKey);
		await secureStorage.delete(key: ioniaPasswordStorageKey);
	}

	// Create virtual card

	Future<IoniaVirtualCard> createCard() async {
		final username = (await secureStorage.read(key: ioniaUsernameStorageKey))!;
		final password = (await secureStorage.read(key: ioniaPasswordStorageKey))!;
		return ioniaApi.createCard(username: username, password: password, clientId: clientId);
	}

	// Get virtual card

	Future<IoniaVirtualCard> getCard() async {
		final username = (await secureStorage.read(key: ioniaUsernameStorageKey))!;
		final password = (await secureStorage.read(key: ioniaPasswordStorageKey))!;
		return ioniaApi.getCards(username: username, password: password, clientId: clientId);
	}

	// Get Merchants

	Future<List<IoniaMerchant>> getMerchants() async {
		final username = (await secureStorage.read(key: ioniaUsernameStorageKey))!;
		final password = (await secureStorage.read(key: ioniaPasswordStorageKey))!;
		return ioniaApi.getMerchants(username: username, password: password, clientId: clientId);
	}

	// Get Merchants By Filter

	Future<List<IoniaMerchant>> getMerchantsByFilter({
		String? search,
		List<IoniaCategory>? categories,
		int merchantFilterType = 0}) async {
		final username = (await secureStorage.read(key: ioniaUsernameStorageKey))!;
		final password = (await secureStorage.read(key: ioniaPasswordStorageKey))!;
		return ioniaApi.getMerchantsByFilter(
			username: username,
			password: password,
			clientId: clientId,
			search: search,
			categories: categories,
			merchantFilterType: merchantFilterType);
	}

	// Purchase Gift Card

	Future<IoniaOrder> purchaseGiftCard({
		required String merchId,
		required double amount,
		required String currency}) async {
		final username = (await secureStorage.read(key: ioniaUsernameStorageKey))!;
		final password = (await secureStorage.read(key: ioniaPasswordStorageKey))!;
		final deviceId = '';
		return ioniaApi.purchaseGiftCard(
			requestedUUID: deviceId,
			merchId: merchId,
			amount: amount,
			currency: currency,
			username: username,
			password: password,
			clientId: clientId);
	}

	// Get Current User Gift Card Summaries

	Future<List<IoniaGiftCard>> getCurrentUserGiftCardSummaries() async {
		final username = (await secureStorage.read(key: ioniaUsernameStorageKey))!;
		final password = (await secureStorage.read(key: ioniaPasswordStorageKey))!;
		return ioniaApi.getCurrentUserGiftCardSummaries(username: username, password: password, clientId: clientId);
	}

	// Charge Gift Card

	Future<void> chargeGiftCard({
		required int giftCardId,
		required double amount}) async {
		final username = (await secureStorage.read(key: ioniaUsernameStorageKey))!;
		final password = (await secureStorage.read(key: ioniaPasswordStorageKey))!;
		await ioniaApi.chargeGiftCard(
			username: username,
			password: password,
			clientId: clientId,
			giftCardId: giftCardId,
			amount: amount);
	}

	// Redeem

	Future<void> redeem({required int giftCardId, required double amount}) async {
		await chargeGiftCard(giftCardId: giftCardId, amount: amount);
	}

	// Get Gift Card

	Future<IoniaGiftCard> getGiftCard({required int id}) async {
		final username = (await secureStorage.read(key: ioniaUsernameStorageKey))!;
		final password = (await secureStorage.read(key: ioniaPasswordStorageKey))!;
		return ioniaApi.getGiftCard(username: username, password: password, clientId: clientId,id: id);
	}

	// Payment Status

	Future<int> getPaymentStatus({
		required String orderId,
		required String paymentId}) async {
		final username = (await secureStorage.read(key: ioniaUsernameStorageKey))!;
		final password = (await secureStorage.read(key: ioniaPasswordStorageKey))!;
		return ioniaApi.getPaymentStatus(username: username, password: password, clientId: clientId, orderId: orderId, paymentId: paymentId);
	}
}