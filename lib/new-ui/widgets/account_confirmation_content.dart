import "package:cake_wallet/entities/calculate_fiat_amount.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/monero_account_list/account_list_item.dart";
import "package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart";
import "package:cw_core/crypto_amount_format.dart";
import "package:flutter/material.dart";

class ArchiveConfirmationContent extends StatelessWidget {
  const ArchiveConfirmationContent({
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
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFunded) ...[
            Text(
              S.of(context).archive_account_funds_title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.customColors.warningOutlineColor,
                  ),
            ),
            const SizedBox(height: 20),
            AccountFundsSummary(
              account: account,
              accountListViewModel: accountListViewModel,
              dashboardViewModel: dashboardViewModel,
              borderColor: context.customColors.warningOutlineColor,
            ),
            const SizedBox(height: 24),
            Text(
              S.of(context).archive_account_move_funds,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.customColors.warningOutlineColor,
                  ),
            ),
            const SizedBox(height: 20),
            Text(
              S.of(context).archive_account_funded_disclaimer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ] else ...[
            AccountSummary(account: account),
            const SizedBox(height: 24),
            Text(
              S.of(context).archive_account_empty_disclaimer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              S.of(context).archive_account_restore_hint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      );
}

class AccountSummary extends StatelessWidget {
  const AccountSummary({required this.account});

  final AccountListItem account;

  @override
  Widget build(BuildContext context) {
    final label = account.label.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CakeImageWidget(
            imageUrl: "assets/new-ui/account.svg",
            width: 24,
            height: 24,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "${account.id + 1}. ",
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                  TextSpan(
                    text: label.isEmpty ? S.of(context).unnamed_account : label,
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountFundsSummary extends StatelessWidget {
  const AccountFundsSummary({
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
    final fiatBalance = accountFiatBalance(account, dashboardViewModel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CakeImageWidget(
            imageUrl: accountListViewModel.currency.iconPath ??
                "assets/new-ui/crypto_full_icons/${accountListViewModel.currency.name.toLowerCase()}.svg",
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${account.balance ?? "0"} ${accountListViewModel.currency.title}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (fiatBalance != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    fiatBalance,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

bool isAccountFunded(AccountListItem account) {
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

String? accountFiatBalance(AccountListItem account, DashboardViewModel dashboardViewModel) {
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
