import "package:cake_wallet/new-ui/pages/wallet_network/wallet_network_page.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class WalletNetworkPageRobot extends BaseRobot {
  WalletNetworkPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<WalletNetworkPage>();
  }

  Future<void> findParticularWalletTypeInScrollableList(WalletType type) =>
      _scrollToKey("wallet_network_${type.name}_row_key");

  Future<void> selectWalletType(WalletType type) async {
    await tapByKey("wallet_network_${type.name}_row_key");
  }

  Finder get _scrollable => find.descendant(
        of: find.byKey(const Key("wallet_network_scrollable_key")),
        matching: find.byType(Scrollable),
      );

  bool hasBuiltinRow(WalletType type) => isKeyPresent("wallet_network_${type.name}_row_key");

  bool hasAddedNetworkRow(int chainId) => isKeyPresent("wallet_network_evm_${chainId}_row_key");

  bool get hasAddEvmNetworksRow => isKeyPresent("wallet_network_add_evm_networks_row_key");

  bool get hasManageAddedNetworksRow => isKeyPresent("wallet_network_manage_added_row_key");

  bool get hasNoNetworksFound => isKeyPresent("wallet_network_no_networks_found_text_key");

  Future<void> search(String query) async {
    final field = find.descendant(
      of: find.byKey(const ValueKey("wallet_network_search_field_key")),
      matching: find.byType(TextField),
    );

    await pumpUntilFound(field);

    await tester.enterText(field.first, query);
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> clearSearch() async {
    await search("");
  }

  Future<void> _scrollToKey(String key) async {
    await pumpUntilFound(_scrollable.first);

    await tester.scrollUntilVisible(
      find.byKey(ValueKey(key)),
      300,
      scrollable: _scrollable.first,
      maxScrolls: 20,
    );

    await settle(max: const Duration(seconds: 1));
  }

  Future<void> _scrollAndTap(String key) async {
    await _scrollToKey(key);

    await tapByKey(key);
  }

  Future<void> openManageBuiltinNetworks() async {
    await _scrollAndTap("wallet_network_manage_builtin_row_key");
  }

  Future<void> openAddEvmNetworks() async {
    await _scrollAndTap("wallet_network_add_evm_networks_row_key");
  }

  Future<void> openManageAddedNetworks() async {
    await _scrollAndTap("wallet_network_manage_added_row_key");
  }

  Future<void> selectAddedNetwork(int chainId) async {
    await _scrollAndTap("wallet_network_evm_${chainId}_row_key");
  }

  Future<bool> waitForAddedNetworkRow(int chainId, {required bool present}) =>
      pumpUntil(() => hasAddedNetworkRow(chainId) == present);

  Future<void> closePicker() async {
    await tapWhenVisible(
      find.descendant(
        of: find.byType(WalletNetworkPage),
        matching: find.byIcon(Icons.arrow_back_ios_new),
      ),
    );

    await pumpUntilGone(find.byType(WalletNetworkPage));
  }

  Future<bool> waitForBuiltinRow(WalletType type, {required bool present}) =>
      pumpUntil(() => hasBuiltinRow(type) == present);
}
