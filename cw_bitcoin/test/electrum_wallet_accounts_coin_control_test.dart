import "dart:typed_data";

import "package:bitcoin_base/bitcoin_base.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_unspent.dart";
import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/coin_control/frozen_coins_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/encryption_file_utils.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

class _FakeFrozenCoinsStore implements FrozenCoinsStore {
  final Map<int, Map<String, bool>> _byWallet = {};

  @override
  Future<Set<String>> frozenIds(int walletInfoId) async =>
      (_byWallet[walletInfoId] ?? const <String, bool>{})
          .entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toSet();

  @override
  Future<void> setFrozen(int walletInfoId, String id, bool frozen) async =>
      _byWallet.putIfAbsent(walletInfoId, () => {})[id] = frozen;

  @override
  Future<void> deleteWallet(int walletInfoId) async => _byWallet.remove(walletInfoId);
}

ElectrumWallet buildWallet() => ElectrumWallet(
      password: "",
      walletInfo: WalletInfo.external(
        id: "bitcoin_accounts_test",
        name: "accounts_test",
        type: WalletType.bitcoin,
        isRecovery: false,
        restoreHeight: 0,
        date: DateTime(2026),
        dirPath: "",
        path: "",
        address: "",
      ),
      derivationInfo: DerivationInfo(
        derivationType: DerivationType.bip39,
        derivationPath: "m/84'/0'/0'",
      ),
      network: BitcoinNetwork.mainnet,
      encryptionFileUtils: encryptionFileUtilsFor(false),
      seedBytes: Uint8List(64),
      currency: CryptoCurrency.btc,
    );

BitcoinUnspent coin(String hash, {required int accountIndex, int value = 1000}) => BitcoinUnspent(
      BitcoinAddressRecord(
        "addr-$hash",
        index: 0,
        accountIndex: accountIndex,
        type: SegwitAddresType.p2wpkh,
        network: BitcoinNetwork.mainnet,
      ),
      hash,
      value,
      0,
    );

void main() {
  final originalStore = FrozenCoinsStore.instance;

  late ElectrumWallet wallet;

  final first = coin("aa", accountIndex: 0, value: 100);
  final second = coin("bb", accountIndex: 0, value: 200);
  final other = coin("cc", accountIndex: 1, value: 400);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FrozenCoinsStore.instance = _FakeFrozenCoinsStore();
    wallet = buildWallet()..unspentCoins = [first, second, other];
  });

  tearDown(() => FrozenCoinsStore.instance = originalStore);

  group("unspents", () {
    test("lists only the current account's coins", () {
      expect(wallet.unspents.map((coin) => coin.id), [first.id, second.id]);

      wallet.walletInfo.currentAccountIndex = 1;

      expect(wallet.unspents.map((coin) => coin.id), [other.id]);
    });
  });

  group("spendableCoins", () {
    test("never offers another account's coins", () async {
      final spendable = await wallet.spendableCoins();

      expect(spendable.map((coin) => coin.id), [first.id, second.id]);
    });

    test("excludes a frozen coin of the current account", () async {
      await wallet.setFrozen(second.id, true);

      final spendable = await wallet.spendableCoins();

      expect(spendable.map((coin) => coin.id), [first.id]);
    });
  });

  group("freezing", () {
    test("counts only the current account's frozen coins", () async {
      await wallet.setFrozen(other.id, true);
      await wallet.setFrozen(first.id, true);

      expect(await wallet.frozenBalance(), first.value);
      expect(wallet.balance[CryptoCurrency.btc]!.frozen, Money.fromInt(first.value, CryptoCurrency.btc));
    });

    test("keeps each account's frozen amount after switching accounts", () async {
      await wallet.setFrozen(first.id, true);

      wallet.walletInfo.currentAccountIndex = 1;
      await wallet.setFrozen(other.id, true);

      expect(wallet.balanceForAccount(0).frozen, Money.fromInt(first.value, CryptoCurrency.btc));
      expect(wallet.balanceForAccount(1).frozen, Money.fromInt(other.value, CryptoCurrency.btc));
      expect(wallet.balance[CryptoCurrency.btc]!.frozen, Money.fromInt(other.value, CryptoCurrency.btc));
    });
  });
}
