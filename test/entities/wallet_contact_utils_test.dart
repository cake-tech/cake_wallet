import "package:cake_wallet/entities/wallet_contact.dart";
import "package:cake_wallet/entities/wallet_contact_group.dart";
import "package:cake_wallet/new-ui/entries/address_book/wallet_contact_entry.dart";
import "package:cake_wallet/new-ui/entries/address_book/wallet_contact_utils.dart";
import "package:cake_wallet/entities/wallet_group.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cake_wallet/utils/token_utilities.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

WalletContact _contact(
  CryptoCurrency type, {
  WalletType? walletType,
  String label = "",
  String address = "addr",
}) =>
    WalletContact(address, "name", type, walletType: walletType, label: label);

WalletInfo _wallet(String id, WalletType type, {String? groupId, bool isReady = true}) =>
    WalletInfo.external(
      id: id,
      name: "wallet $id",
      type: type,
      isRecovery: false,
      restoreHeight: 0,
      date: DateTime(2026),
      dirPath: "",
      path: "",
      address: "address_$id",
      groupId: groupId,
      isReady: isReady,
    );

WalletContactEntry _entry(String walletId, WalletType type, String address,
        {CryptoCurrency currency = CryptoCurrency.btc, String label = "", int? accountIndex}) =>
    WalletContactEntry(
      walletId: walletId,
      walletName: "wallet $walletId",
      walletType: type,
      address: address,
      currency: currency,
      label: label,
      displayLabel: label,
      accountIndex: accountIndex,
    );

void main() {
  setUpAll(() => S.current = const S());

  group("isContactValidForCurrency", () {
    bool valid(WalletContact c, CryptoCurrency? currency,
            {bool isWalletContact = true, ChainIdForWalletType? chainId}) =>
        isContactValidForCurrency(c, currency,
            isWalletContact: isWalletContact, chainIdForWalletType: chainId);

    test("no currency accepts everything, even non-pickable contacts", () {
      expect(valid(_contact(CryptoCurrency.btc, label: "P2WPKH"), null), isTrue);
    });

    test("exact currency match", () {
      expect(valid(_contact(CryptoCurrency.xmr), CryptoCurrency.xmr), isTrue);
      expect(valid(_contact(CryptoCurrency.xmr), CryptoCurrency.btc), isFalse);
    });

    test("non-pickable BTC/LTC wallet contacts are rejected only as wallet contacts", () {
      final p2wpkh = _contact(CryptoCurrency.btc, label: "P2WPKH");
      expect(valid(p2wpkh, CryptoCurrency.btc), isFalse);
      expect(valid(p2wpkh, CryptoCurrency.btc, isWalletContact: false), isTrue);
      expect(valid(_contact(CryptoCurrency.btc, label: "Active - P2WPKH"), CryptoCurrency.btc),
          isTrue);
    });

    test("tag/tag, tag/title and title/tag matches", () {
      // usdcpoly.tag == maticpoly.tag ("POL")
      expect(valid(_contact(CryptoCurrency.maticpoly), CryptoCurrency.usdcpoly), isTrue);
      // usdc.tag ("ETH") == eth.title
      expect(valid(_contact(CryptoCurrency.eth), CryptoCurrency.usdc), isTrue);
      // eth.title == usdc.tag
      expect(valid(_contact(CryptoCurrency.usdc), CryptoCurrency.eth), isTrue);
    });

    test("EVM wallet contacts must be on the currency's chain", () {
      final chain = TokenUtilities.getChainId(CryptoCurrency.usdc);
      int chainId(WalletType type) => type == WalletType.ethereum ? chain : chain + 1;
      final onEthereum = _contact(CryptoCurrency.eth, walletType: WalletType.ethereum);
      final onBase = _contact(CryptoCurrency.eth, walletType: WalletType.base);

      expect(valid(onEthereum, CryptoCurrency.usdc, chainId: chainId), isTrue);
      expect(valid(onBase, CryptoCurrency.usdc, chainId: chainId), isFalse);
    });

    test("no chain-id resolver (no EVM proxy) skips the chain check", () {
      final onBase = _contact(CryptoCurrency.eth, walletType: WalletType.base);
      expect(valid(onBase, CryptoCurrency.usdc), isTrue);
    });
  });

  group("WalletContactGroup.networkContacts", () {
    WalletContactGroup groupOf(List<WalletContact> contacts) => WalletContactGroup(
          groupId: "g",
          name: "G",
          icon: WalletIcon.defaultIcon,
          isCurrent: true,
          contacts: contacts,
        );

    test("one row per network, active address preferred, first-seen order", () {
      final xmr0 = _contact(CryptoCurrency.xmr, walletType: WalletType.monero, address: "xmr0");
      final xmr1 = _contact(CryptoCurrency.xmr, walletType: WalletType.monero, address: "xmr1");
      final btcOther = _contact(CryptoCurrency.btc,
          walletType: WalletType.bitcoin, label: "P2TR", address: "btc-taproot");
      final btcActive = _contact(CryptoCurrency.btc,
          walletType: WalletType.bitcoin, label: "Active - P2WPKH", address: "btc-active");

      final rows = groupOf([xmr0, btcOther, xmr1, btcActive]).networkContacts;

      expect(rows.map((c) => c.address), ["xmr0", "btc-active"]);
    });

    test("rows are keyed by walletType ?? type", () {
      final rows = groupOf([
        _contact(CryptoCurrency.btc, address: "a"),
        _contact(CryptoCurrency.ltc, address: "b"),
        _contact(CryptoCurrency.btc, address: "c"),
      ]).networkContacts;

      expect(rows.map((c) => c.address), ["a", "b"]);
    });
  });

  group("buildWalletContactGroups", () {
    final btc = _wallet("btc", WalletType.bitcoin, groupId: "g1");
    final xmr = _wallet("xmr", WalletType.monero, groupId: "g1");
    final placeholder = _wallet("eth", WalletType.ethereum, groupId: "g1", isReady: false);
    final single = _wallet("ltc", WalletType.litecoin, groupId: "g2");

    final groups = [
      WalletGroup("g2", wallets: [single]),
      WalletGroup("g1",
          wallets: [btc, xmr, placeholder], groupName: "My Wallet", icon: WalletIcon.defaultIcon),
    ];
    final entries = {
      "btc": [_entry("btc", WalletType.bitcoin, "btc-addr", label: "Active")],
      "xmr": [
        _entry("xmr", WalletType.monero, "xmr-addr", currency: CryptoCurrency.xmr, accountIndex: 0)
      ],
      "ltc": [_entry("ltc", WalletType.litecoin, "ltc-addr", currency: CryptoCurrency.ltc)],
      "eth": [_entry("eth", WalletType.ethereum, "should-not-show", currency: CryptoCurrency.eth)],
    };

    test("maps groups by id, current first, names from the group", () {
      final result = buildWalletContactGroups(
          groups: groups, entriesByWalletId: entries, currentGroupId: "g1");

      expect(result.map((g) => g.groupId), ["g1", "g2"]);
      final current = result.first;
      expect(current.isCurrent, isTrue);
      expect(current.name, "My Wallet");
      expect(current.contacts.map((c) => c.address), ["btc-addr", "xmr-addr"]);
      expect(current.contacts.map((c) => c.name),
          ["My Wallet · Bitcoin (Active)", "My Wallet · Monero [#0]"]);
      expect(current.contacts.every((c) => c.groupId == "g1"), isTrue);
    });

    test("a group without a name falls back to the wallet name and the default icon", () {
      final result = buildWalletContactGroups(groups: groups, entriesByWalletId: entries);
      final unnamed = result.firstWhere((g) => g.groupId == "g2");

      expect(unnamed.name, "wallet ltc");
      expect(unnamed.icon, WalletIcon.defaultIcon);
      expect(unnamed.contacts.single.name, "wallet ltc");
    });

    test("the currency filter drops non-matching contacts and empty groups", () {
      final result = buildWalletContactGroups(
          groups: groups, entriesByWalletId: entries, currency: CryptoCurrency.xmr);

      expect(result.map((g) => g.groupId), ["g1"]);
      expect(result.single.contacts.map((c) => c.address), ["xmr-addr"]);
    });
  });
}
