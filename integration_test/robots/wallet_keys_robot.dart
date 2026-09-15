import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/src/screens/wallet_keys/wallet_keys_page.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/monero_wallet_keys.dart";
import "package:cw_core/wallet_type.dart";
import "package:cw_monero/monero_wallet.dart";
import "package:flutter_test/flutter_test.dart";
import "package:polyseed/polyseed.dart";

import "../core/base_robot.dart";

class WalletKeysAndSeedPageRobot extends BaseRobot {
  WalletKeysAndSeedPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<WalletKeysPage>();
  }

  int _verifiedCredentials = 0;

  Future<void> confirmWalletCredentials(WalletType walletType) async {
    _verifiedCredentials = 0;

    final walletKeysPage = tester.widget<WalletKeysPage>(find.byType(WalletKeysPage));
    final walletKeysViewModel = walletKeysPage.walletKeysViewModel;

    final appStore = walletKeysViewModel.appStore;
    final walletName = walletType.name;
    final hasSeed = appStore.wallet!.seed != null;
    final hasHexSeed = appStore.wallet!.hexSeed != null;
    final hasPrivateKey = appStore.wallet!.privateKey != null;

    if (walletType == WalletType.monero) {
      final moneroWallet = appStore.wallet! as MoneroWalletBase;
      final lang = PolyseedLang.getByPhrase(moneroWallet.seed);
      final legacySeed = moneroWallet.seedLegacy(lang.nameEnglish);

      await _confirmMoneroWalletCredentials(
        appStore,
        walletName,
        moneroWallet.seed,
        legacySeed,
      );
    }

    if (walletType == WalletType.bitcoin ||
        walletType == WalletType.litecoin ||
        walletType == WalletType.bitcoinCash) {
      final seedWords = appStore.wallet!.seed!.split(" ");
      for (final seedWord in seedWords) {
        hasTextAtLeastOnce(seedWord);
      }
      _verifiedCredentials++;
      tester.printToConsole("$walletName wallet has seeds properly displayed");
    }

    if (isEVMCompatibleChain(walletType) ||
        walletType == WalletType.solana ||
        walletType == WalletType.tron) {
      if (hasSeed) {
        final seedWords = appStore.wallet!.seed!.split(" ");
        for (final seedWord in seedWords) {
          hasTextAtLeastOnce(seedWord);
        }
        _verifiedCredentials++;
        tester.printToConsole("$walletName wallet has seeds properly displayed");
      }
      if (hasPrivateKey) {
        await _openKeysTab();
        hasText(appStore.wallet!.privateKey!);
        _verifiedCredentials++;
        tester.printToConsole("$walletName wallet has private key properly displayed");
      }
    }

    if (walletType == WalletType.nano || walletType == WalletType.banano) {
      if (hasSeed) {
        final seedWords = appStore.wallet!.seed!.split(" ");
        for (final seedWord in seedWords) {
          hasTextAtLeastOnce(seedWord);
        }
        _verifiedCredentials++;
        tester.printToConsole("$walletName wallet has seeds properly displayed");
      }
      if (hasHexSeed) {
        await _openKeysTab();
        hasText(appStore.wallet!.hexSeed!);
        _verifiedCredentials++;
        tester.printToConsole("$walletName wallet has hexSeed properly displayed");
      }
      if (hasPrivateKey) {
        await _openKeysTab();
        hasText(appStore.wallet!.privateKey!);
        _verifiedCredentials++;
        tester.printToConsole("$walletName wallet has private key properly displayed");
      }
    }

    _expectSomethingWasVerified(walletType);
  }

  void _expectSomethingWasVerified(WalletType walletType) {
    expect(
      _verifiedCredentials,
      greaterThan(0),
      reason: "Nothing was verified for ${walletType.name}, this suite covers no credential "
          "for that type so it cannot tell a working keys page from a broken one",
    );
  }

  Future<void> _openKeysTab() async {
    await tapByKey("wallet_keys_page_keys");

    await settle();
  }

  void _hasKeyRow(String value) {
    expect(find.text(value, skipOffstage: false), findsOneWidget);
  }

  Future<void> _confirmMoneroWalletCredentials(
    AppStore appStore,
    String walletName,
    String seed,
    String legacySeed,
  ) async {
    final keys = appStore.wallet!.keys as MoneroWalletKeys;
    final hasSeeds = seed.isNotEmpty;
    final hasSeedLegacy = Polyseed.isValidSeed(seed);

    await _openKeysTab();

    _hasKeyRow(keys.publicSpendKey);
    _verifiedCredentials++;
    tester.printToConsole("$walletName wallet has public spend key properly displayed");

    _hasKeyRow(keys.privateSpendKey);
    _verifiedCredentials++;
    tester.printToConsole("$walletName wallet has private spend key properly displayed");

    _hasKeyRow(keys.publicViewKey);
    _verifiedCredentials++;
    tester.printToConsole("$walletName wallet has public view key properly displayed");

    _hasKeyRow(keys.privateViewKey);
    _verifiedCredentials++;
    tester.printToConsole("$walletName wallet has private view key properly displayed");

    if (hasSeeds) {
      await tapByKey("wallet_keys_page_seed");
      await settle();

      final seedWords = seed.split(" ");
      for (final seedWord in seedWords) {
        hasTextAtLeastOnce(seedWord);
      }
      _verifiedCredentials++;
      tester.printToConsole("$walletName wallet has seeds properly displayed");
    }
    if (hasSeedLegacy) {
      await tapByKey("wallet_keys_page_seed_legacy");
      await settle();

      final seedWords = legacySeed.split(" ");
      for (final seedWord in seedWords) {
        hasTextAtLeastOnce(seedWord);
      }
      _verifiedCredentials++;
      tester.printToConsole("$walletName wallet has legacy seeds properly displayed");
    }
  }
}
