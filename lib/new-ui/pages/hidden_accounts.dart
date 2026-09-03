import "dart:async";

import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/entities/calculate_fiat_amount.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/base_alert_dialog.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/monero_account_list/account_list_item.dart";
import "package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart";
import "package:cw_core/balance_card_layout.dart";
import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/crypto_amount_format.dart";
import "package:flutter/material.dart";

Future<bool> confirmAccountArchival(
  BuildContext context, {
  required AccountListItem account,
  required MoneroAccountListViewModel accountListViewModel,
  required DashboardViewModel dashboardViewModel,
}) async {
  final strings = S.of(context);
  final isFunded = _isFunded(account);

  final result = await showPopUp<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertWithTwoActions(
      alertTitle:
          isFunded ? strings.archive_account_confirmation_title : strings.archive_account_title,
      alertContent: "",
      alertContentTextWidget: _ArchiveConfirmationContent(
        account: account,
        accountListViewModel: accountListViewModel,
        dashboardViewModel: dashboardViewModel,
        isFunded: isFunded,
      ),
      leftButtonText: strings.cancel,
      rightButtonText: strings.continue_text,
      leftAlertButtonStyle: AlertButtonStyle.primary(dialogContext),
      rightAlertButtonStyle: AlertButtonStyle.secondary(dialogContext),
      actionLeftButton: () => Navigator.of(dialogContext).pop(false),
      actionRightButton: () => Navigator.of(dialogContext).pop(true),
    ),
  );

  return result ?? false;
}

Future<bool> confirmAccountUnarchival(
  BuildContext context, {
  required AccountListItem account,
  required MoneroAccountListViewModel accountListViewModel,
  required DashboardViewModel dashboardViewModel,
}) async {
  final strings = S.of(context);
  final isFunded = _isFunded(account);

  final result = await showPopUp<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertWithTwoActions(
      alertTitle: strings.unarchive_account_title,
      alertContent: "",
      alertContentTextWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AccountSummary(account: account),
          const SizedBox(height: 20),
          Text(
            isFunded
                ? strings.unarchive_account_funds_description
                : strings.unarchive_account_description,
            textAlign: TextAlign.center,
            style: Theme.of(dialogContext).textTheme.bodyMedium,
          ),
          if (isFunded) ...[
            const SizedBox(height: 20),
            _FundsSummary(
              account: account,
              accountListViewModel: accountListViewModel,
              dashboardViewModel: dashboardViewModel,
              borderColor: Theme.of(dialogContext).colorScheme.primary,
            ),
          ],
        ],
      ),
      leftButtonText: strings.cancel,
      rightButtonText: strings.continue_text,
      leftAlertButtonStyle: AlertButtonStyle.secondary(dialogContext),
      rightAlertButtonStyle: AlertButtonStyle.primary(dialogContext),
      actionLeftButton: () => Navigator.of(dialogContext).pop(false),
      actionRightButton: () => Navigator.of(dialogContext).pop(true),
    ),
  );

  return result ?? false;
}

class HiddenAccountsPage extends StatefulWidget {
  const HiddenAccountsPage({
    required this.accountListViewModel,
    required this.dashboardViewModel,
    super.key,
  });

  final MoneroAccountListViewModel accountListViewModel;
  final DashboardViewModel dashboardViewModel;

  @override
  State<HiddenAccountsPage> createState() => _HiddenAccountsPageState();
}

class _HiddenAccountsPageState extends State<HiddenAccountsPage> {
  final List<AccountListItem> _items = [];
  final Set<int> _accountsBeingRestored = <int>{};
  bool _isLoading = true;

  int get _walletInfoId => widget.dashboardViewModel.wallet.walletInfo.internalId;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAccounts());
  }

  Future<BalanceCardLayout> _layout() async => BalanceCardLayout.resolve(
        accountIndices: widget.accountListViewModel.accounts.map((account) => account.id).toList(),
        settings: await BalanceCardStyleSettings.getAll(_walletInfoId),
      );

  Future<void> _loadAccounts() async {
    final accounts = widget.accountListViewModel.accounts;
    final layout = await _layout();
    final hiddenAccounts = <AccountListItem>[];

    for (final accountIndex in layout.hidden) {
      final account = accounts.firstWhereOrNull((account) => account.id == accountIndex);
      if (account != null) {
        hiddenAccounts.add(account);
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(hiddenAccounts);
      _isLoading = false;
    });
  }

  Future<void> _unarchive(AccountListItem account) async {
    final accountForConfirmation =
        widget.accountListViewModel.accounts.firstWhereOrNull((item) => item.id == account.id) ??
            account;
    final confirmed = await confirmAccountUnarchival(
      context,
      account: accountForConfirmation,
      accountListViewModel: widget.accountListViewModel,
      dashboardViewModel: widget.dashboardViewModel,
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _accountsBeingRestored.add(account.id));
    try {
      final restored = (await _layout()).unhiding(account.id);
      await BalanceCardStyleSettings.setVisibleOrder(_walletInfoId, restored.orders);
      final latestAccount =
          widget.accountListViewModel.accounts.firstWhereOrNull((item) => item.id == account.id) ??
              account;
      widget.accountListViewModel.select(latestAccount);
      await widget.dashboardViewModel.loadCardDesigns();
      await _loadAccounts();
    } finally {
      if (mounted) {
        setState(() => _accountsBeingRestored.remove(account.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ModalPageWrapper(
        topBar: ModalTopBar(
          title: S.of(context).archived_accounts,
          leadingIcon: const Icon(Icons.arrow_back_ios_new, size: 18),
          leadingSemanticLabel: S.of(context).seed_alert_back,
          onLeadingPressed: Navigator.of(context).pop,
        ),
        content: _isLoading
            ? const SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator()),
              )
            : _items.isEmpty
                ? const _EmptyArchiveView()
                : _PopulatedArchiveView(
                    accounts: _items,
                    accountsBeingRestored: _accountsBeingRestored,
                    accountListViewModel: widget.accountListViewModel,
                    dashboardViewModel: widget.dashboardViewModel,
                    onUnarchive: _unarchive,
                  ),
      );
}

class _EmptyArchiveView extends StatelessWidget {
  const _EmptyArchiveView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height - 180,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ArchiveIcon(size: 50, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                S.of(context).no_archived_accounts,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Text(
                S.of(context).no_archived_accounts_description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopulatedArchiveView extends StatelessWidget {
  const _PopulatedArchiveView({
    required this.accounts,
    required this.accountsBeingRestored,
    required this.accountListViewModel,
    required this.dashboardViewModel,
    required this.onUnarchive,
  });

  final List<AccountListItem> accounts;
  final Set<int> accountsBeingRestored;
  final MoneroAccountListViewModel accountListViewModel;
  final DashboardViewModel dashboardViewModel;
  final Future<void> Function(AccountListItem account) onUnarchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fundedAccounts = accounts.where(_isFunded).toList(growable: false);
    final emptyAccounts = accounts.where((account) => !_isFunded(account)).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ArchiveIcon(size: 50, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 36),
          child: Text(
            S.of(context).select_account_to_unarchive,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (fundedAccounts.isNotEmpty) ...[
          _ArchiveSectionHeader(
            title: S.of(context).funded_accounts,
            description: S.of(context).funded_accounts_description,
          ),
          const SizedBox(height: 12),
          _accountRows(context, fundedAccounts),
        ],
        if (fundedAccounts.isNotEmpty && emptyAccounts.isNotEmpty) const SizedBox(height: 28),
        if (emptyAccounts.isNotEmpty) ...[
          _ArchiveSectionHeader(title: S.of(context).empty_accounts),
          const SizedBox(height: 12),
          _accountRows(context, emptyAccounts),
        ],
      ],
    );
  }

  Widget _accountRows(BuildContext context, List<AccountListItem> sectionAccounts) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var index = 0; index < sectionAccounts.length; index++) ...[
              _ArchivedAccountRow(
                account: sectionAccounts[index],
                accountListViewModel: accountListViewModel,
                dashboardViewModel: dashboardViewModel,
                isBusy: accountsBeingRestored.contains(sectionAccounts[index].id),
                onTap: accountsBeingRestored.contains(sectionAccounts[index].id)
                    ? null
                    : () => onUnarchive(sectionAccounts[index]),
              ),
              if (index < sectionAccounts.length - 1)
                Divider(
                  height: 1,
                  indent: 48,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
            ],
          ],
        ),
      );
}

class _ArchivedAccountRow extends StatelessWidget {
  const _ArchivedAccountRow({
    required this.account,
    required this.accountListViewModel,
    required this.dashboardViewModel,
    required this.isBusy,
    required this.onTap,
  });

  final AccountListItem account;
  final MoneroAccountListViewModel accountListViewModel;
  final DashboardViewModel dashboardViewModel;
  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _ArchiveIcon(size: 22, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _accountName(context, account),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _AccountBalanceTrailing(
                  account: account,
                  accountListViewModel: accountListViewModel,
                  dashboardViewModel: dashboardViewModel,
                  isBusy: isBusy,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchiveSectionHeader extends StatelessWidget {
  const _ArchiveSectionHeader({required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountBalanceTrailing extends StatelessWidget {
  const _AccountBalanceTrailing({
    required this.account,
    required this.accountListViewModel,
    required this.dashboardViewModel,
    required this.isBusy,
  });

  final AccountListItem account;
  final MoneroAccountListViewModel accountListViewModel;
  final DashboardViewModel dashboardViewModel;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isBusy) {
      return const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final fiatBalance = _fiatBalance(account, dashboardViewModel);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 142),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${_displayBalance(account)} ${accountListViewModel.currency.title}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              if (fiatBalance != null) ...[
                const SizedBox(height: 2),
                Text(
                  fiatBalance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _ArchiveConfirmationContent extends StatelessWidget {
  const _ArchiveConfirmationContent({
    required this.account,
    required this.accountListViewModel,
    required this.dashboardViewModel,
    required this.isFunded,
  });

  final AccountListItem account;
  final MoneroAccountListViewModel accountListViewModel;
  final DashboardViewModel dashboardViewModel;
  final bool isFunded;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFunded) ...[
          Text(
            strings.archive_account_funds_title,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.customColors.warningOutlineColor,
            ),
          ),
          const SizedBox(height: 20),
          _FundsSummary(
            account: account,
            accountListViewModel: accountListViewModel,
            dashboardViewModel: dashboardViewModel,
            borderColor: context.customColors.warningOutlineColor,
          ),
          const SizedBox(height: 24),
          Text(
            strings.archive_account_move_funds,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.customColors.warningOutlineColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            strings.archive_account_funded_disclaimer,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ] else ...[
          _AccountSummary(account: account),
          const SizedBox(height: 24),
          Text(
            strings.archive_account_empty_disclaimer,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            strings.archive_account_restore_hint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.account});

  final AccountListItem account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _ArchiveIcon(size: 22, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _accountName(context, account),
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _FundsSummary extends StatelessWidget {
  const _FundsSummary({
    required this.account,
    required this.accountListViewModel,
    required this.dashboardViewModel,
    required this.borderColor,
  });

  final AccountListItem account;
  final MoneroAccountListViewModel accountListViewModel;
  final DashboardViewModel dashboardViewModel;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = accountListViewModel.currency;
    final fiatBalance = _fiatBalance(account, dashboardViewModel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CakeImageWidget(
            imageUrl: currency.iconPath ??
                "assets/new-ui/crypto_full_icons/${currency.name.toLowerCase()}.svg",
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_displayBalance(account)} ${currency.title}",
                  style: theme.textTheme.bodyMedium,
                ),
                if (fiatBalance != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    fiatBalance,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveIcon extends StatelessWidget {
  const _ArchiveIcon({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Icon(
          Icons.archive_outlined,
          size: size,
          color: color,
        ),
      );
}

bool _isFunded(AccountListItem account) {
  if (account.balance?.contains("●") ?? false) {
    return true;
  }
  return (_accountAmount(account) ?? 0) > 0;
}

double? _accountAmount(AccountListItem account) {
  final balance = account.balance;
  if (balance == null) {
    return null;
  }
  return double.tryParse(balance.trim().replaceAll(",", ""));
}

String _accountName(BuildContext context, AccountListItem account) {
  final label = account.label.trim();
  return "${account.id + 1}. ${label.isEmpty ? S.of(context).unnamed_account : label}";
}

String _displayBalance(AccountListItem account) => account.balance ?? "0";

String? _fiatBalance(AccountListItem account, DashboardViewModel dashboardViewModel) {
  if (dashboardViewModel.balanceViewModel.isFiatDisabled) {
    return null;
  }

  final fiat = dashboardViewModel.settingsStore.fiatCurrency.title;
  if (account.balance?.contains("●") ?? false) {
    return "●●●●● $fiat";
  }

  final amount = _accountAmount(account);
  if (amount == null) {
    return null;
  }

  final value = calculateFiatAmount(
    price: dashboardViewModel.balanceViewModel.price,
    cryptoAmount: amount.toString(),
  ).withLocalSeperator(dashboardViewModel.settingsStore.languageCode);
  return "$value $fiat";
}
