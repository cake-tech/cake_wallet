import "dart:async";
import "dart:ui";

import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/utils/show_card_customizer.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/screens/settings/widgets/account_creation_modal.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/wallet_account_list/account_edit_or_create_view_model.dart";
import "package:cake_wallet/view_model/wallet_account_list/account_list_item.dart";
import "package:cake_wallet/view_model/wallet_account_list/wallet_account_list_view_model.dart";
import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/card_design.dart";
import "package:cw_core/sync_status.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:mobx/mobx.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class AccountCustomizerListItem {
  AccountCustomizerListItem({
    required this.card,
    required this.order,
    required this.accountListItem,
  });

  final BalanceCard card;
  final int order;
  final AccountListItem accountListItem;
}

class WalletAccountsPage extends StatefulWidget {
  const WalletAccountsPage({
    required this.accountListViewModel,
    required this.accountEditOrCreateViewModel,
    required this.dashboardViewModel,
    super.key,
  });

  final WalletAccountListViewModel accountListViewModel;
  final WalletAccountEditOrCreateViewModel accountEditOrCreateViewModel;
  final DashboardViewModel dashboardViewModel;

  @override
  State<WalletAccountsPage> createState() => _WalletAccountsPageState();
}

class _WalletAccountsPageState extends State<WalletAccountsPage> {
  static const double _kStackVisibleFactor = 0.2;
  late final double cardWidth = MediaQuery.of(context).size.width * 0.9;

  final List<AccountCustomizerListItem> _items = [];

  ReactionDisposer? _accountsReaction;

  WalletAccountListViewModel get accountListViewModel =>
      widget.dashboardViewModel.accountListViewModel ?? widget.accountListViewModel;

  bool get _isMultiAccountsEnabled =>
      widget.dashboardViewModel.isMultiAccountsEnabled;

  String get _assetName => widget.dashboardViewModel.appStore.amountParsingProxy
      .getCryptoSymbol(accountListViewModel.currency);


  bool get _capitalizeAssetName =>
      widget.dashboardViewModel.wallet.type != WalletType.bitcoin ||
          widget.dashboardViewModel.settingsStore.displayAmountsInSatoshi !=
              BitcoinAmountDisplayMode.satoshi;

  @override
  void initState() {
    super.initState();

    _accountsReaction = reaction(
      (_) => accountListViewModel.accounts
          .map((account) => "${account.id}:${account.label}")
          .join(","),
      (_) {
        if (!mounted) return;
        loadCards();
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.dashboardViewModel.loadCardDesigns();
      if (!mounted) return;
      loadCards();

      if (!_isMultiAccountsEnabled) return;

      final activeId = accountListViewModel.selectedAccount?.id;

      for (int i = 0; i < _items.length - 1; i++) {
        if (activeId != null && _items[i].accountListItem.id == activeId) {
          final lastIndex = _items.length - 1;
          final temp = _items[i];
          _items[i] = _items[lastIndex];
          _items[lastIndex] = temp;

          await saveCardOrder();
          await widget.dashboardViewModel.loadCardDesigns();
          loadCards();
          break;
        }
      }
    });
  }

  @override
  void dispose() {
    _accountsReaction?.call();
    accountListViewModel.reload();
    saveCardOrder().then((value) => widget.dashboardViewModel.loadCardDesigns());
    super.dispose();
  }

  void loadCards() {
    final allAccounts = accountListViewModel.accounts;
    final visible = widget.dashboardViewModel.visibleAccounts;

    if (visible.isEmpty && _items.isNotEmpty) return;

    _items.clear();

    if (!_isMultiAccountsEnabled) {
      if (visible.isNotEmpty) {
        final account = visible.first;
        final realIndex = allAccounts.indexWhere((a) => a.id == account.id);
        final design = (realIndex >= 0 &&
                realIndex < widget.dashboardViewModel.cardDesigns.length)
            ? widget.dashboardViewModel.cardDesigns[realIndex]
            : CardDesign.genericDefault;

        _items.add(AccountCustomizerListItem(
          card: BalanceCard(
            accountName: account.label,
            accountIndex: account.id,
            balance: account.balance ?? "0.00",
            accountBalance: account.balance ?? "0.00",
            designSwitchDuration: Duration.zero,
            assetName: _assetName,
            capitalizeAssetName: _capitalizeAssetName,
            selected: true,
            width: cardWidth,
            design: design,
          ),
          order: realIndex >= 0 ? realIndex : 0,
          accountListItem: account,
        ));
      }
      if (mounted) setState(() {});
      return;
    }

    for (int i = 0; i < allAccounts.length; i++) {
      final realIndex = widget.dashboardViewModel.cardOrder[i];

      if (realIndex == null || realIndex < 0 || realIndex >= allAccounts.length) {
        // db order broken.
        reset();
        break;
      }

      _items.add(AccountCustomizerListItem(
          card: BalanceCard(
            accountName: allAccounts[realIndex].label,
            accountIndex: allAccounts[realIndex].id,
            balance: allAccounts[realIndex].balance ?? "0.00",
            accountBalance: allAccounts[realIndex].balance ?? "0.00",
            designSwitchDuration: Duration.zero,
            assetName: _assetName,
            capitalizeAssetName: _capitalizeAssetName,
            selected: i == allAccounts.length - 1,
            width: cardWidth,
            design: widget.dashboardViewModel.cardDesigns[realIndex],
          ),
          order: realIndex,
          accountListItem: allAccounts[realIndex]));
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final showResetButton = _isMultiAccountsEnabled && _items.length > 1;
    final showAccountsToggle = widget.dashboardViewModel.canToggleMultiAccounts;
    final isToggleEnabled = widget.dashboardViewModel.multiAccountsToggleValue;

    if (_items.isEmpty && !showAccountsToggle) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          ModalTopBar(
            title: S.of(context).wallet_accounts,
            leadingIcon: const Icon(Icons.close),
            leadingSemanticLabel: S.of(context).close,
            onLeadingPressed: Navigator.of(context).maybePop,
            trailingIcon: showResetButton ? const Icon(Icons.refresh) : null,
            trailingSemanticLabel: S.of(context).reset,
            onTrailingPressed: showResetDialog,
          ),
          const SizedBox(height: 24),
          if (showAccountsToggle)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: NewListSections(
                sections: {
                  "": [
                    ListItemToggle(
                        keyValue: "Multiple Accounts",
                        label: "Multiple Accounts",
                        value: isToggleEnabled,
                        onChanged: (val) async {
                          await widget.dashboardViewModel.setMultiAccountsEnabled(val);
                          if (!mounted) return;
                          loadCards();
                        }),
                  ],
                },
              ),
            ),
          if (_isMultiAccountsEnabled && _items.isNotEmpty)
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      S.of(context).account_customizer_desc,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        ReorderableListView.builder(
                          padding: const EdgeInsets.only(bottom: 196),
                          scrollController: ModalScrollController.of(context),
                          onReorder: reorder,
                          proxyDecorator: (child, index, animation) => AnimatedBuilder(
                            animation: animation,
                            builder: (context, _) {
                              final animValue = Curves.easeOutCubic.transform(animation.value);
                              final scale = lerpDouble(1, 1.05, animValue)!;

                              return Opacity(
                                opacity: 1 - animValue.clamp(0.0, 0.1),
                                child: Center(
                                  child: SizedBox(
                                    width: cardWidth,
                                    child: Transform.scale(
                                      scale: scale,
                                      child: child,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: _items[index].card,
                          ),
                          itemCount: _items.length,
                          itemBuilder: (context, int index) {
                            final card = _items[index].card;
                            final selectedItemIndex = _items.length - 1;

                            return Container(
                              key: ValueKey(index),
                              child: Semantics(
                                button: true,
                                selected: selectedItemIndex == index,
                                label: _items[index].accountListItem.label,
                                onTap: () => reorder(index, _items.length),
                                child: GestureDetector(
                                  excludeFromSemantics: true,
                                  onTap: () => reorder(index, _items.length),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    heightFactor: _kStackVisibleFactor,
                                    child: card,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 50),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Material(
                                  color: Colors.transparent,
                                  child: MergeSemantics(
                                    child: Semantics(
                                      button: true,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(999999),
                                        onTap: _showAddAccountModal,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surfaceContainer,
                                            borderRadius: BorderRadius.circular(999999),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 18),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              spacing: 8,
                                              children: [
                                                Icon(
                                                  Icons.add,
                                                  size: 28,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                                Text(
                                                  S.of(context).add_account,
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.primary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _checkReadyToManage() {
    if (widget.dashboardViewModel.wallet.type == WalletType.bitcoin) {
      return true;
    }
    if (widget.dashboardViewModel.status is! SyncedSyncStatus) {
      showDialog(
        context: context,
        builder: (context) => AlertWithOneAction(
          alertTitle: S.of(context).wallet_is_syncing,
          alertContent: S.of(context).cannot_manage_accounts_during_sync,
          buttonText: S.of(context).ok,
          buttonAction: Navigator.of(context).pop,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _showAddAccountModal() async {
    if (!_checkReadyToManage()) return;

    final createViewModel = getIt.get<WalletAccountEditOrCreateViewModel>();

    final res = await showCupertinoModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Material(
          child: AccountCreationModal(
            viewModel: createViewModel,
          ),
        ));

    if (res != null && res is bool && res == true) {
      await accountListViewModel.reload();
      await Future<void>.delayed(Duration.zero);

      final accounts = accountListViewModel.accounts;
      if (accounts.isNotEmpty) {
        final newestAccount = accounts.reduce((a, b) => a.id > b.id ? a : b);
        await accountListViewModel.select(newestAccount);
      }

      await widget.dashboardViewModel.loadCardDesigns();
      loadCards();
      if (mounted) setState(() {});
    }
  }

  Future<void> _openCardCustomizer() async {
    if (!_checkReadyToManage()) {
      return;
    }

    await showCardCustomizer(
      context: context,
      dashboardViewModel: widget.dashboardViewModel,
      lightningMode: widget.dashboardViewModel.lightningMode,
      asModalSheet: false,
      onSaved: _reloadAccountsAndCards,
    );
  }

  Future<void> _reloadAccountsAndCards() async {
    await accountListViewModel.reload();
    await widget.dashboardViewModel.loadCardDesigns();
    if (!mounted) return;
    loadCards();
  }

  void _onCardsReordered(int oldRealIndex, int newRealIndex) {
    final accounts = accountListViewModel.accounts;
    if (oldRealIndex < 0 ||
        newRealIndex < 0 ||
        oldRealIndex >= accounts.length ||
        newRealIndex >= accounts.length) {
      return;
    }

    final oldAccountId = accounts[oldRealIndex].id;
    final newAccountId = accounts[newRealIndex].id;

    final from = _items.indexWhere((item) => item.accountListItem.id == oldAccountId);
    final to = _items.indexWhere((item) => item.accountListItem.id == newAccountId);
    if (from < 0 || to < 0 || from == to) return;

    final insertIndex = from < to ? to + 1 : to;
    reorder(from, insertIndex);

    saveCardOrder().then((_) {
      if (!mounted) return;
      widget.dashboardViewModel.loadCardDesigns();
    });
  }

  void reorder(int oldIndex, int newIndex) {
    if (!_isMultiAccountsEnabled) return;
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final AccountCustomizerListItem item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });

    // necessary to copy all this to keep constant constructor for BalanceCard
    for (int i = 0; i < _items.length; i++) {
      _items[i] = AccountCustomizerListItem(
          card: BalanceCard(
            accountName: _items[i].card.accountName,
            balance: _items[i].card.balance,
            accountIndex: _items[i].card.accountIndex,
            accountBalance: _items[i].card.accountBalance,
            assetName: _items[i].card.assetName,
            capitalizeAssetName: _items[i].card.capitalizeAssetName,
            designSwitchDuration: _items[i].card.designSwitchDuration,
            onCustomizeTapped: (i == _items.length - 1) ? _openCardCustomizer : null,
            selected: i == _items.length - 1,
            width: _items[i].card.width,
            design: _items[i].card.design,
          ),
          order: i,
          accountListItem: _items[i].accountListItem);
    }

    if (newIndex == _items.length - 1 || oldIndex == _items.length - 1) {
      accountListViewModel.select(_items[_items.length - 1].accountListItem);
    }
  }

  Future<void> saveCardOrder() async {

    if (!_isMultiAccountsEnabled) return;

    for (int orderIndex = 0; orderIndex < _items.length; orderIndex++) {
      final item = _items[orderIndex];
      printV("${item.accountListItem.id}: $orderIndex");

      final existing = await BalanceCardStyleSettings.get(
        widget.dashboardViewModel.wallet.walletInfo.internalId,
        item.accountListItem.id,
      );

      await BalanceCardStyleSettings.fromCardDesign(
              walletInfoId: widget.dashboardViewModel.wallet.walletInfo.internalId,
              accountIndex: item.accountListItem.id,
              cardOrder: orderIndex,
              design: item.card.design,
              iconStyleIndex: existing?.iconStyleIndex ?? 0,
              gradientIndexOverride: existing?.gradientIndex)
          .insert();
    }
  }

  Future<void> showResetDialog() async {
    final res = await showPopUp(
        context: context,
        builder: (context) => AlertWithTwoActions(
            alertTitle: S.of(context).reset,
            alertContent: S.of(context).card_order_reset_desc,
            leftButtonText: S.of(context).yes,
            rightButtonText: S.of(context).no,
            actionLeftButton: () {
              Navigator.of(context).pop(true);
            },
            actionRightButton: Navigator.of(context).pop));
    if (res != null && res is bool && res) {
      reset();
    }
  }

  Future<void> reset() async {
    _items.clear();

    final accounts = accountListViewModel.accounts;
    for (int i = 0; i < accounts.length; i++) {
      _items.add(AccountCustomizerListItem(
          card: BalanceCard(
            accountName: accounts[i].label,
            accountIndex: accounts[i].id,
            balance: accounts[i].balance ?? "0.00",
            accountBalance: accounts[i].balance ?? "0.00",
            assetName: _assetName,
            capitalizeAssetName: _capitalizeAssetName,
            selected: i == accounts.length - 1,
            designSwitchDuration: const Duration(milliseconds: 200),
            width: cardWidth,
            design: i >= widget.dashboardViewModel.cardDesigns.length
                ? CardDesign.genericDefault
                : widget.dashboardViewModel.cardDesigns[i],
          ),
          order: i,
          accountListItem: accounts[i]));
    }

    await saveCardOrder();

    if (accounts.isNotEmpty) {
      await accountListViewModel.select(accounts.last);
    }

    await widget.dashboardViewModel.loadCardDesigns();
    if (mounted) setState(() {});
  }
}
