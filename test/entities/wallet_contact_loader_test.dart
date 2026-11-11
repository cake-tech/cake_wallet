import "dart:io";

import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/entities/contact.dart";
import "package:cake_wallet/entities/contact_base.dart";
import "package:cake_wallet/entities/wallet_contact.dart";
import "package:cake_wallet/new-ui/entries/address_book/wallet_contact_loader.dart";
import "package:cake_wallet/entities/wallet_list_order_types.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/utils/token_utilities.dart";
import "package:cake_wallet/view_model/contact_list/contact_list_view_model.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:mocktail/mocktail.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

class _MockContactBox extends Mock implements Box<Contact> {}

class _MockSettingsStore extends Mock implements SettingsStore {}

Future<WalletInfo> _saveWallet(
  String id,
  WalletType type, {
  String address = "",
  bool isReady = true,
  Map<String, String> addresses = const {},
  Map<int, List<(String address, String label)>> accounts = const {},
}) async {
  final info = WalletInfo.external(
    id: id,
    name: "wallet_$id",
    type: type,
    isRecovery: false,
    restoreHeight: 0,
    date: DateTime(2026),
    dirPath: "",
    path: "",
    address: address,
    groupId: "group",
    isReady: isReady,
  );
  await info.save();
  if (addresses.isNotEmpty) await info.setAddresses(addresses);
  if (accounts.isNotEmpty) {
    await info.setAddressInfos({
      for (final MapEntry(:key, :value) in accounts.entries)
        key: [
          for (final (address, label) in value)
            WalletInfoAddressInfo(
              walletInfoId: info.internalId,
              mapKey: key,
              accountIndex: key,
              address: address,
              label: label,
            ),
        ],
    });
  }
  return info;
}

/// Verbatim copy (addresses only) of the pre-refactor `ContactListViewModel.loadWalletContacts`.
Future<List<WalletContact>> _legacyLoadWalletContacts() async {
  final loadedContacts = <WalletContact>[];
  for (final info in await WalletInfo.getAll()) {
    final addressInfos = await info.getAddressInfos();
    final addresses = await info.getAddresses();
    if ([WalletType.monero, WalletType.wownero, WalletType.haven].contains(info.type) &&
        addressInfos.isNotEmpty) {
      for (var key in addressInfos.keys) {
        final address = addressInfos[key]?.first;
        if (address != null) {
          loadedContacts.add(WalletContact(
              address.address, "", getCryptoCurrencyForWalletListItem(info.type),
              walletType: info.type));
        }
      }
    } else if (addresses.isNotEmpty == true && addresses.length > 1) {
      if ([WalletType.monero, WalletType.wownero, WalletType.haven, WalletType.decred]
          .contains(info.type)) {
        loadedContacts.add(WalletContact(
            info.address, "", getCryptoCurrencyForWalletListItem(info.type),
            walletType: info.type));
      } else {
        addresses.forEach((address, label) {
          if (label.isEmpty) return;
          loadedContacts.add(WalletContact(
            address,
            "",
            getCryptoCurrencyForWalletListItem(info.type,
                isTestnet:
                    info.network == null ? false : info.network!.toLowerCase().contains("testnet")),
            walletType: info.type,
            label: label,
          ));
        });
      }
    } else {
      loadedContacts.add(WalletContact(
          info.address, "", getCryptoCurrencyForWalletListItem(info.type),
          walletType: info.type));
    }
  }
  return loadedContacts;
}

/// Verbatim copy of the pre-refactor `ContactListViewModel._isValidForCurrency`.
bool _legacyIsValidForCurrency(
    ContactBase element, bool isWalletContact, CryptoCurrency? currency) {
  if (currency == null) return true;
  if (isWalletContact && element is WalletContact && !element.isPickable) return false;
  final currencyMatches = element.type == currency;
  final tagsMatch =
      element.type.tag != null && currency.tag != null && element.type.tag == currency.tag;
  final tagMatchesTitle = currency.tag != null && currency.tag == element.type.title;
  final titleMatchesTag = currency.title == element.type.tag;
  var matches = currencyMatches || tagsMatch || tagMatchesTitle || titleMatchesTag;
  if (matches && isWalletContact && element is WalletContact && element.walletType != null) {
    final walletType = element.walletType!;
    if (isEVMCompatibleChain(walletType)) {
      final currencyChainId = TokenUtilities.getChainId(currency);
      final walletChainId = evm!.getChainIdByWalletType(walletType);
      if (currencyChainId != walletChainId) matches = false;
    }
  }
  return matches;
}

void main() {
  final dataRoot = Directory("./test/data/wallet_contact_loader");

  setUpAll(() async {
    S.current = const S();
    if (dataRoot.existsSync()) dataRoot.deleteSync(recursive: true);
    Directory("${dataRoot.path}/cake_wallet").createSync(recursive: true);
    PathProviderPlatform.instance = _FakePathProviderPlatform(dataRoot.absolute.path);
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initDb();
  });

  setUp(() async {
    await db!.delete(WalletInfoAddressInfo.tableName);
    await db!.delete(WalletInfo.tableName);
  });

  tearDownAll(() async {
    await db?.close();
    db = null;
    if (dataRoot.existsSync()) dataRoot.deleteSync(recursive: true);
  });

  Future<void> seedWallets() async {
    await _saveWallet("xmr", WalletType.monero, address: "xmr_main", accounts: {
      2: [("xmr_acc2", "Spending")],
      0: [("xmr_acc0", "Primary account")],
      1: [("xmr_acc1", "Savings")],
    });
    await _saveWallet("xmr_plain", WalletType.monero, address: "xmr_plain_main");
    await _saveWallet("btc", WalletType.bitcoin, address: "bc1_active", addresses: {
      "bc1_active": "Active - P2WPKH",
      "bc1_taproot": "P2TR",
      "bc1_unlabelled": "",
    });
    await _saveWallet("ltc", WalletType.litecoin, address: "ltc_main");
    await _saveWallet("dcr", WalletType.decred,
        address: "dcr_main", addresses: {"dcr_1": "a", "dcr_2": "b"});
    await _saveWallet("eth", WalletType.ethereum, address: "0xeth");
    // Omnichain placeholder: no address yet.
    await _saveWallet("eth_placeholder", WalletType.ethereum, isReady: false);
  }

  group("loadWalletContactEntries", () {
    test("Monero/Wownero/Haven accounts are sorted with #0 first", () async {
      await seedWallets();
      final info = (await WalletInfo.getAll()).firstWhere((w) => w.id == "xmr");

      final entries = await loadWalletContactEntries(info);

      expect(entries.map((e) => e.accountIndex), [0, 1, 2]);
      expect(entries.map((e) => e.address), ["xmr_acc0", "xmr_acc1", "xmr_acc2"]);
      expect(entries.first.toContact(groupName: "My Wallet").name,
          "My Wallet · Monero [#0] (Primary account)");
    });

    test("labelled addresses only, decred uses the wallet address, placeholders skipped", () async {
      await seedWallets();
      final byId = {for (final w in await WalletInfo.getAll()) w.id: w};

      final btc = await loadWalletContactEntries(byId["btc"]!);
      expect(btc.map((e) => e.address), ["bc1_active", "bc1_taproot"]);
      expect(btc.map((e) => e.label), ["Active - P2WPKH", "P2TR"]);

      final dcr = await loadWalletContactEntries(byId["dcr"]!);
      expect(dcr.map((e) => e.address), ["dcr_main"]);

      final plainXmr = await loadWalletContactEntries(byId["xmr_plain"]!);
      expect(plainXmr.single.accountIndex, 0);

      expect(await loadWalletContactEntries(byId["eth_placeholder"]!), isEmpty);
    });
  });

  group("ContactListViewModel.walletContactsToShow wrapper", () {
    late ContactListViewModel Function(CryptoCurrency? currency) createVm;

    setUp(() {
      final box = _MockContactBox();
      when(() => box.values).thenReturn(const []);
      when(() => box.watch()).thenAnswer((_) => const Stream.empty());

      final settings = _MockSettingsStore();
      when(() => settings.autoGenerateSubaddressStatus)
          .thenReturn(AutoGenerateSubaddressStatus.disabled);
      when(() => settings.contactListOrder).thenReturn(FilterListOrderType.Custom);

      createVm = (currency) => ContactListViewModel(box, const [], currency, settings);
    });

    for (final currency in <CryptoCurrency?>[
      null,
      CryptoCurrency.btc,
      CryptoCurrency.xmr,
      CryptoCurrency.dcr,
      CryptoCurrency.eth,
      CryptoCurrency.usdc,
    ]) {
      test("same addresses as the old implementation (currency: ${currency?.title})", () async {
        await seedWallets();

        final vm = createVm(currency);
        await vm.loadWalletContacts();
        final actual = vm.walletContactsToShow.map((c) => c.address).toSet();

        final legacy = (await _legacyLoadWalletContacts())
            .where((c) => _legacyIsValidForCurrency(c, true, currency))
            .map((c) => c.address)
            .toSet();

        // Only intended difference: the placeholder's empty address is gone.
        expect(actual, legacy.difference({""}));
        vm.dispose();
      });
    }
  });
}
