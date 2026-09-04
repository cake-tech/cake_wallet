import "dart:async";
import "dart:math";
import "dart:ui";

import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/calculate_fiat_amount.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/account_education_page.dart";
import "package:cake_wallet/new-ui/pages/card_customizer.dart";
import "package:cake_wallet/new-ui/pages/hidden_accounts.dart";
import "package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/monero_account_list/account_list_item.dart";
import "package:cake_wallet/view_model/monero_account_list/monero_account_edit_or_create_view_model.dart";
import "package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart";
import "package:cw_core/balance_card_layout.dart";
import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/card_design.dart";
import "package:cw_core/crypto_amount_format.dart";
import "package:cw_core/generate_name.dart";
import "package:cw_core/sync_status.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

bool supportsAccountEducationAndArchival(WalletType walletType) => walletType == WalletType.monero;

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

class AccountCustomizer extends StatefulWidget {
  const AccountCustomizer({
    required this.accountListViewModel,
    required this.dashboardViewModel,
    super.key,
  });

  final MoneroAccountListViewModel accountListViewModel;
  final DashboardViewModel dashboardViewModel;

  @override
  State<AccountCustomizer> createState() => _AccountCustomizerState();
}

class _AccountCustomizerState extends State<AccountCustomizer> {
  static const double _kStackVisibleFactor = 0.2;

  final List<AccountCustomizerListItem> _items = [];
  bool _hasArchivedAccounts = false;
  int? _accountBeingArchivedId;
  bool _loading = true;

  double get cardWidth => min(MediaQuery.sizeOf(context).width * 0.9, 768);

  bool get _supportsAccountArchival =>
      supportsAccountEducationAndArchival(widget.dashboardViewModel.wallet.type);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_initialize()));
  }

  Future<void> _initialize() async {
    await _bringActiveAccountToFront();
    if (!mounted || _items.isEmpty) {
      return;
    }

    final preferences = widget.dashboardViewModel.sharedPreferences;
    if (_supportsAccountArchival && AccountEducationPage.shouldShow(preferences)) {
      await AccountEducationPage.show(context, preferences);
    }
  }

  @override
  void dispose() {
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

      newItems.add(
        AccountCustomizerListItem(
          card: BalanceCard(
            accountName: "${account.id + 1}. $accountLabel",
            balance: account.balance ?? "0.00",
            accountBalance: account.balance ?? "0.00",
            fiatBalance: _fiatBalance(account),
            designSwitchDuration: Duration.zero,
            assetName: widget.accountListViewModel.currency.title,
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
              trailingWidget: _supportsAccountArchival
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        ModernButton(
                          semanticLabel: S.of(context).accounts_help,
                          icon: const Icon(Icons.question_mark),
                          size: 36,
                          iconSize: 19,
                          onPressed: () => AccountEducationPage.show(
                            context,
                            widget.dashboardViewModel.sharedPreferences,
                          ),
                        ),
                        ModernButton(
                          semanticLabel: S.of(context).archived_accounts,
                          icon: const Icon(Icons.inventory_2_outlined),
                          size: 36,
                          iconSize: 19,
                          backgroundColor:
                              _hasArchivedAccounts ? Theme.of(context).colorScheme.primary : null,
                          iconColor:
                              _hasArchivedAccounts ? Theme.of(context).colorScheme.onPrimary : null,
                          onPressed: _openArchivedAccounts,
                        ),
                      ],
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
              child: Text(
                S.of(context).account_customizer_desc,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      );

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
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
          itemBuilder: (context, index) {
            final card = _items[index].card;
            final selectedItemIndex = _items.length - 1;

            return Container(
              key: ValueKey(_items[index].accountListItem.id),
              child: Semantics(
                button: true,
                selected: selectedItemIndex == index,
                label: "${_items[index].accountListItem.id + 1}. "
                    "${_items[index].accountListItem.label.trim().isEmpty ? S.of(context).unnamed_account : _items[index].accountListItem.label}",
                onTap: () => reorder(index, _items.length),
                child: GestureDetector(
                  excludeFromSemantics: true,
                  onTap: () {
                    reorder(index, _items.length);
                  },
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

  bool _checkReadyToManage() {
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
    if (!_checkReadyToManage()) {
      return;
    }

    final res = await showCupertinoModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      expand: true,
      enableDrag: false,
      builder: (context) {
        final modal = getIt.get<AccountCreationModal>();
        return Material(child: modal);
      },
    );
    if (res != null && res is bool && res == true) {
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
    widget.accountListViewModel.select(account);

    final bloc = getIt.get<CardCustomizerBloc>(
      param1: CardCustomizerBlocParams(
        lightningMode: false,
        amountDisplayMode: null,
        canHide: _supportsAccountArchival && _items.length > 1,
      ),
    );

    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (context) => BlocProvider.value(
          value: bloc,
          child: Material(
            child: CardCustomizer(
              cryptoTitle: widget.dashboardViewModel.wallet.currency.fullName ??
                  widget.dashboardViewModel.wallet.currency.name,
              cryptoName: widget.dashboardViewModel.wallet.currency.name,
              accountNumber: account.id + 1,
              balance: account.balance ?? "0.00",
              fiatBalance: _fiatBalance(account),
              onArchive: _supportsAccountArchival
                  ? () {
                      final latestAccount = widget.accountListViewModel.accounts
                              .firstWhereOrNull((item) => item.id == account.id) ??
                          account;
                      return confirmAccountArchival(
                        context,
                        account: AccountListItem(
                          id: latestAccount.id,
                          label: bloc.state.accountName,
                          balance: latestAccount.balance,
                          isSelected: latestAccount.isSelected,
                        ),
                        accountListViewModel: widget.accountListViewModel,
                        dashboardViewModel: widget.dashboardViewModel,
                      );
                    }
                  : null,
            ),
          ),
        ),
      ),
    );

    final hideRequested = result == true;
    _accountBeingArchivedId = hideRequested ? account.id : null;
    if (hideRequested) {
      // Persist edits made on this screen before AccountHidden stores the hidden state.
      // AccountHidden intentionally owns only hidden state.
      bloc.add(DesignSaved());
      await bloc.stream.firstWhere((item) => item is CardCustomizerSaved);
      bloc.add(AccountHidden());
    } else {
      bloc.add(DesignSaved());
    }
    await bloc.stream.firstWhere((item) => item is CardCustomizerSaved);
    if (hideRequested && _items.length > 1) {
      final nextAccount = _items[_items.length - 2].accountListItem;
      widget.accountListViewModel.select(
        widget.accountListViewModel.accounts
                .firstWhereOrNull((item) => item.id == nextAccount.id) ??
            nextAccount,
      );
    }
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

  String _fiatBalance(AccountListItem account) {
    final balanceViewModel = widget.dashboardViewModel.balanceViewModel;
    if (balanceViewModel.isFiatDisabled) {
      return "";
    }

    final fiat = widget.dashboardViewModel.settingsStore.fiatCurrency.title;
    final balance = account.balance ?? "0";
    if (balance.contains("●")) {
      return "$fiat ●●●●●";
    }

    final amount = double.tryParse(balance.trim().replaceAll(",", ""));
    if (amount == null) {
      return "";
    }

    final value = calculateFiatAmount(
      price: balanceViewModel.price,
      cryptoAmount: amount.toString(),
    ).withLocalSeperator(widget.dashboardViewModel.settingsStore.languageCode);
    return "$fiat $value";
  }
}

class AccountCreationModal extends StatefulWidget {
  const AccountCreationModal({required this.accountEditOrCreateViewModel, super.key});

  final MoneroAccountEditOrCreateViewModel accountEditOrCreateViewModel;

  @override
  State<AccountCreationModal> createState() => _AccountCreationModalState();
}

class _AccountCreationModalState extends State<AccountCreationModal> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  bool get _canContinue => _controller.text.trim().isNotEmpty;

  Future<void> _generateAccountName() async {
    final generatedName = await generateName();
    if (!mounted) {
      return;
    }
    setState(() => _controller.text = generatedName);
  }

  Future<void> _save() async {
    if (_loading || !_canContinue) {
      return;
    }

    setState(() => _loading = true);
    widget.accountEditOrCreateViewModel.label = _controller.text;

    late final String errorMessage;
    try {
      await widget.accountEditOrCreateViewModel.save();
      if (!mounted) {
        return;
      }

      final state = widget.accountEditOrCreateViewModel.state;
      if (state is ExecutedSuccessfullyState) {
        Navigator.of(context).pop(true);
        return;
      }
      errorMessage = state is FailureState ? state.error : S.of(context).error_while_processing;
    } catch (error) {
      errorMessage = error.toString();
    }

    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertWithOneAction(
        alertTitle: S.of(dialogContext).error,
        alertContent: errorMessage,
        buttonText: S.of(dialogContext).ok,
        buttonAction: Navigator.of(dialogContext).pop,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_loading,
        child: _buildContent(context),
      );

  Widget _buildContent(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
              children: [
                ModalTopBar(
                  title: S.of(context).create_account,
                  trailingIcon: const Icon(Icons.close),
                  trailingSemanticLabel: S.of(context).close,
                  onTrailingPressed: Navigator.of(context).maybePop,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 32, 18, 24),
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/new-ui/account_education/create_account.png",
                          width: 125,
                          height: 125,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          S.of(context).account_creation_description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: S.of(context).account_name,
                                    counterText: "",
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Semantics(
                                  button: true,
                                  label: S.of(context).generate_name,
                                  onTap: _generateAccountName,
                                  child: ExcludeSemantics(
                                    child: GestureDetector(
                                      onTap: _generateAccountName,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: CakeImageWidget(
                                          imageUrl: "assets/new-ui/randomize.svg",
                                          colorFilter: ColorFilter.mode(
                                            Theme.of(context).colorScheme.primary,
                                            BlendMode.srcIn,
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
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: NewPrimaryButton(
                      onPressed: _save,
                      text: S.of(context).continue_text,
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                      isLoading: _loading,
                      disabled: !_canContinue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
