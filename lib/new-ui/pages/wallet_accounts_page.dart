import "dart:async";
import "dart:math";
import "dart:ui";

import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/core/amount_parsing_proxy.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/src/screens/settings/widgets/account_creation_modal.dart";
import "package:cw_core/wallet_type.dart";
import "package:mobx/mobx.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/account_education_page.dart";
import "package:cake_wallet/new-ui/pages/card_customizer.dart";
import "package:cake_wallet/new-ui/pages/hidden_accounts.dart";
import "package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/wallet_account_list/account_list_item.dart";
import "package:cake_wallet/view_model/wallet_account_list/account_edit_or_create_view_model.dart";
import "package:cake_wallet/view_model/wallet_account_list/wallet_account_list_view_model.dart";
import "package:cw_core/balance_card_layout.dart";
import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/card_design.dart";
import "package:cw_core/sync_status.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class AccountCustomizerListItem {
  const AccountCustomizerListItem({
    required this.card,
    required this.accountListItem,
    required this.settings,
  });

  final BalanceCard card;
  final AccountListItem accountListItem;
  final BalanceCardStyleSettings? settings;
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
  final List<AccountCustomizerListItem> _items = [];
  bool _hasArchivedAccounts = false;
  int? _accountBeingArchivedId;
  bool _loading = true;
  ReactionDisposer? _accountsReaction;

  bool get _isMultiAccountsEnabled => widget.dashboardViewModel.isMultiAccountsEnabled;

  String get _assetName => AmountParsingProxy(
        widget.dashboardViewModel.settingsStore.displayAmountsInSatoshi,
      ).getCryptoSymbol(widget.accountListViewModel.currency);

  bool get _capitalizeAssetName =>
      widget.dashboardViewModel.wallet.type != WalletType.bitcoin ||
      widget.dashboardViewModel.settingsStore.displayAmountsInSatoshi !=
          BitcoinAmountDisplayMode.satoshi;

  double get cardWidth => min(MediaQuery.sizeOf(context).width * 0.9, 768);

  @override
  void initState() {
    super.initState();
    _accountsReaction = reaction(
      (_) => (
        widget.dashboardViewModel.settingsStore.balanceDisplayMode,
        widget.dashboardViewModel.settingsStore.displayAmountsInSatoshi,
        widget.accountListViewModel.accounts
            .map((account) => "${account.id}:${account.label}:${account.balance}")
            .join(","),
      ),
      (_) {
        if (mounted) unawaited(loadCards());
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_initialize()));
  }

  Future<void> _initialize() async {
    await widget.dashboardViewModel.loadCardDesigns();
    if (!mounted) return;
    await _bringActiveAccountToFront();
    if (!mounted || !_isMultiAccountsEnabled || _items.isEmpty) {
      return;
    }

    final educationPage = AccountEducationPage(
      settingsStore: widget.dashboardViewModel.settingsStore,
    );
    if (!educationPage.isDismissed) {
      await educationPage.show(context);
    }
  }

  @override
  void dispose() {
    _accountsReaction?.call();
    saveCardOrder(excludingAccountId: _accountBeingArchivedId)
        .then((value) => widget.dashboardViewModel.loadCardDesigns());
    super.dispose();
  }

  int get _walletInfoId => widget.dashboardViewModel.wallet.walletInfo.internalId;

  Future<void> _bringActiveAccountToFront() async {
    await loadCards();

    final activeAccount =
        widget.accountListViewModel.accounts.firstWhereOrNull((account) => account.isSelected);
    if (activeAccount == null || _items.isEmpty) {
      return;
    }

    final index = _items.indexWhere((item) => item.accountListItem.id == activeAccount.id);
    if (index == -1 || index == _items.length - 1 || !mounted) {
      return;
    }

    reorder(index, _items.length);
    await saveCardOrder();
    await widget.dashboardViewModel.loadCardDesigns();
  }

  Future<void> loadCards() async {
    if (!mounted) return;
    final accounts = widget.accountListViewModel.accounts;
    final unnamedAccount = S.of(context).unnamed_account;
    final resolvedCardWidth = cardWidth;
    final walletCurrency = widget.dashboardViewModel.wallet.currency;
    final styleSettings = await BalanceCardStyleSettings.getAll(_walletInfoId);
    final layout = BalanceCardLayout.resolve(
      accountIndices: accounts.map((account) => account.id).toList(),
      settings: styleSettings,
    );

    final List<AccountCustomizerListItem> newItems = [];
    for (int position = 0; position < layout.visible.length; position++) {
      final accountIndex = layout.visible[position];
      final account = accounts.firstWhereOrNull((item) => item.id == accountIndex);

      if (account == null) {
        continue;
      }

      final setting = layout.settingFor(accountIndex);
      final isFrontCard = position == layout.visible.length - 1;
      final accountLabel = account.label.trim().isEmpty ? unnamedAccount : account.label;
      final balance = widget.dashboardViewModel.balanceViewModel.accountBalance(account);

      newItems.add(
        AccountCustomizerListItem(
          card: BalanceCard(
            accountName: "${account.id + 1}. $accountLabel",
            balance: balance,
            accountBalance: balance,
            fiatBalance: widget.dashboardViewModel.balanceViewModel
                    .accountFiatBalance(account, currencyPrefix: true) ??
                "",
            designSwitchDuration: Duration.zero,
            assetName: _assetName,
            capitalizeAssetName: _capitalizeAssetName,
            onCustomizeTapped: isFrontCard ? _openCardCustomizer : null,
            selected: isFrontCard,
            width: resolvedCardWidth,
            design: CardDesign.fromStyleSettings(setting, walletCurrency),
          ),
          accountListItem: account,
          settings: setting,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _items
          ..clear()
          ..addAll(newItems);
        _hasArchivedAccounts = layout.hidden.isNotEmpty;
        _loading = false;
      });
    }

    if (layout.needsRepair) {
      await BalanceCardStyleSettings.setVisibleOrder(_walletInfoId, layout.orders);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            ModalTopBar(
              title: S.of(context).accounts,
              leadingIcon: const Icon(Icons.close),
              leadingSemanticLabel: S.of(context).close,
              onLeadingPressed: Navigator.of(context).maybePop,
              trailingWidget: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  ModernButton(
                    semanticLabel: S.of(context).accounts_help,
                    icon: const Icon(Icons.question_mark),
                    size: 36,
                    iconSize: 19,
                    onPressed: () => AccountEducationPage(
                      settingsStore: widget.dashboardViewModel.settingsStore,
                    ).show(context),
                  ),
                  if (_isMultiAccountsEnabled)
                    ModernButton.svg(
                      semanticLabel: S.of(context).archived_accounts,
                      svgPath: "assets/new-ui/archived.svg",
                      size: 36,
                      iconSize: 19,
                      backgroundColor:
                          _hasArchivedAccounts ? Theme.of(context).colorScheme.primary : null,
                      iconColor:
                          _hasArchivedAccounts ? Theme.of(context).colorScheme.onPrimary : null,
                      onPressed: _openArchivedAccounts,
                    ),
                ],
              ),
            ),
            if (widget.dashboardViewModel.canToggleMultiAccounts)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: NewListSections(sections: {
                  "": [
                    ListItemToggle(
                      keyValue: S.of(context).multiple_accounts,
                      label: S.of(context).multiple_accounts,
                      value: _isMultiAccountsEnabled,
                      onChanged: (value) async {
                        await widget.dashboardViewModel.setMultiAccountsEnabled(value);
                        if (mounted) await _initialize();
                      },
                    ),
                  ],
                }),
              ),
            if (_isMultiAccountsEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
                child: Text(
                  S.of(context).account_customizer_desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            Expanded(
              child: !_isMultiAccountsEnabled
                  ? const SizedBox.shrink()
                  : _loading
                      ? const Center(child: CupertinoActivityIndicator())
                      : _items.isEmpty
                          ? const SizedBox.shrink()
                          : _AccountCards(
                              items: _items,
                              cardWidth: cardWidth,
                              onReorder: reorder,
                              onAddAccount: _showAddAccountModal,
                            ),
            ),
          ],
        ),
      );

  bool _checkReadyToManage() {
    if (widget.dashboardViewModel.wallet.type != WalletType.bitcoin &&
        widget.dashboardViewModel.status is! SyncedSyncStatus) {
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
    if (!_checkReadyToManage()) {
      return;
    }

    final modal = AccountCreationModal(viewModel: widget.accountEditOrCreateViewModel);
    final res = await showCupertinoModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      expand: true,
      enableDrag: false,
      builder: (_) => Material(child: modal),
    );
    if (res == true && mounted) {
      await widget.accountListViewModel.reload();
      final accounts = widget.accountListViewModel.accounts;
      if (accounts.isNotEmpty) {
        await widget.accountListViewModel.select(
          accounts.reduce((a, b) => a.id > b.id ? a : b),
        );
      }
      await widget.dashboardViewModel.loadCardDesigns();
      await loadCards();
      await saveCardOrder();
    }
  }

  Future<void> _openArchivedAccounts() async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute(
        builder: (context) => Material(
          child: HiddenAccountsPage(
            accountListViewModel: widget.accountListViewModel,
            dashboardViewModel: widget.dashboardViewModel,
          ),
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await widget.dashboardViewModel.loadCardDesigns();
    await loadCards();
  }

  Future<void> _openCardCustomizer() async {
    if (!_checkReadyToManage()) {
      return;
    }

    final account = _items.last.accountListItem;
    await widget.accountListViewModel.select(account);
    if (!mounted) return;

    final bloc = getIt.get<CardCustomizerBloc>(
      param1: CardCustomizerBlocParams(
        lightningMode: false,
        amountDisplayMode: widget.dashboardViewModel.settingsStore.displayAmountsInSatoshi,
        canHide: _items.length > 1,
      ),
    );

    if (bloc.state is CardCustomizerNotLoaded) {
      await bloc.stream.firstWhere((state) => state is! CardCustomizerNotLoaded);
    }
    if (!mounted) {
      await bloc.close();
      return;
    }
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (context) => BlocProvider.value(
          value: bloc,
          child: Material(
            child: CardCustomizer(
              cryptoTitle: widget.dashboardViewModel.wallet.currency.fullName ??
                  widget.dashboardViewModel.wallet.currency.name,
              cryptoName: widget.dashboardViewModel.wallet.currency.name,
              dashboardViewModel: widget.dashboardViewModel,
              account: account,
              accountListViewModel: widget.accountListViewModel,
            ),
          ),
        ),
      ),
    );

    final hideRequested = result == true;
    _accountBeingArchivedId = hideRequested ? account.id : null;
    // Save edits before AccountHidden writes the hidden state.
    bloc.add(DesignSaved());
    await bloc.stream.firstWhere((item) => item is CardCustomizerSaved);
    if (hideRequested) {
      bloc.add(AccountHidden());
      await bloc.stream.firstWhere((item) => item is CardCustomizerSaved);
    }
    if (hideRequested && _items.length > 1) {
      final nextAccount = _items[_items.length - 2].accountListItem;
      await widget.accountListViewModel.select(
        widget.accountListViewModel.accounts
                .firstWhereOrNull((item) => item.id == nextAccount.id) ??
            nextAccount,
      );
    }
    await bloc.close();
    await widget.accountListViewModel.reload();
    await widget.dashboardViewModel.loadCardDesigns();
    if (!mounted) {
      return;
    }
    await loadCards();
    if (!mounted) {
      return;
    }

    _accountBeingArchivedId = null;
  }

  void reorder(int oldIndex, int newIndex) {
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
          fiatBalance: _items[i].card.fiatBalance,
          assetName: _items[i].card.assetName,
          capitalizeAssetName: _items[i].card.capitalizeAssetName,
          designSwitchDuration: _items[i].card.designSwitchDuration,
          onCustomizeTapped: (i == _items.length - 1) ? _openCardCustomizer : null,
          selected: i == _items.length - 1,
          width: _items[i].card.width,
          design: _items[i].card.design,
        ),
        accountListItem: _items[i].accountListItem,
        settings: _items[i].settings,
      );
    }

    if (newIndex == _items.length - 1 || oldIndex == _items.length - 1) {
      widget.accountListViewModel.select(_items[_items.length - 1].accountListItem);
    }
  }

  Future<void> saveCardOrder({int? excludingAccountId}) async {
    if (!_isMultiAccountsEnabled) return;
    for (int position = 0; position < _items.length; position++) {
      final item = _items[position];
      if (item.accountListItem.id == excludingAccountId) {
        continue;
      }

      await BalanceCardStyleSettings.fromCardDesign(
        walletInfoId: _walletInfoId,
        accountIndex: item.accountListItem.id,
        hidden: false,
        cardOrder: position,
        design: item.card.design,
        iconStyleIndex: item.settings?.iconStyleIndex ?? 0,
        gradientIndexOverride: item.settings?.gradientIndex,
      ).insert();
    }
  }
}

class _AccountCards extends StatelessWidget {
  const _AccountCards({
    required this.items,
    required this.cardWidth,
    required this.onReorder,
    required this.onAddAccount,
  });

  static const double _kStackVisibleFactor = 0.2;

  final List<AccountCustomizerListItem> items;
  final double cardWidth;
  final ReorderCallback onReorder;
  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 196),
            scrollController: ModalScrollController.of(context),
            onReorder: onReorder,
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
              child: items[index].card,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final selectedItemIndex = items.length - 1;

              return Container(
                key: ValueKey(items[index].accountListItem.id),
                child: Semantics(
                  button: true,
                  selected: selectedItemIndex == index,
                  label: "${items[index].accountListItem.id + 1}. "
                      "${items[index].accountListItem.label.trim().isEmpty ? S.of(context).unnamed_account : items[index].accountListItem.label}",
                  onTap: () => onReorder(index, items.length),
                  child: GestureDetector(
                    excludeFromSemantics: true,
                    onTap: () {
                      onReorder(index, items.length);
                    },
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _kStackVisibleFactor,
                      child: items[index].card,
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
                          onTap: onAddAccount,
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
                                  ),
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
      );
}
