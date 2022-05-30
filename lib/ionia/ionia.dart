import 'package:cake_wallet/ionia/ionia_virtual_card.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/ionia/ionia_api.dart';

class IoniaService {
	IoniaService(this.secureStorage, this.ioniaApi);

	static const ioniaUsernameStorageKey = 'ionia_username';
	static const ioniaPasswordStorageKey = 'ionia_password';

	static String get clientId => secrets.ioniaClientId;

	final FlutterSecureStorage secureStorage;
	final IoniaApi ioniaApi;

	// Create user

	Future<void> createUser(String email) async {
		final username = await ioniaApi.createUser(email, clientId: clientId);
		await secureStorage.write(key: ioniaUsernameStorageKey, value: username);
	}

	// Verify email

	Future<void> verifyEmail(String code) async {
		final username = await secureStorage.read(key: ioniaUsernameStorageKey);
		final credentials = await ioniaApi.verifyEmail(username: username, code: code, clientId: clientId);
		await secureStorage.write(key: ioniaPasswordStorageKey, value: credentials.password);
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
		final username = await secureStorage.read(key: ioniaUsernameStorageKey);
		final password = await secureStorage.read(key: ioniaPasswordStorageKey);
		return ioniaApi.createCard(username: username, password: password, clientId: clientId);
	}

	// Get virtual card

	Future<IoniaVirtualCard> getCard() async {
		final username = await secureStorage.read(key: ioniaUsernameStorageKey);
		final password = await secureStorage.read(key: ioniaPasswordStorageKey);
		return ioniaApi.getCards(username: username, password: password, clientId: clientId);
	}
}