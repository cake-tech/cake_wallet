import 'package:cake_wallet/core/utilities.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/account_list_item.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:cw_core/balance_card_style_settings.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class HiddenAccountsPage extends StatefulWidget {
  const HiddenAccountsPage(
      {super.key, required this.accountListViewModel, required this.dashboardViewModel});

  final MoneroAccountListViewModel accountListViewModel;
  final DashboardViewModel dashboardViewModel;

  @override
  State<HiddenAccountsPage> createState() => _HiddenAccountsPageState();
}

class _HiddenAccountsPageState extends State<HiddenAccountsPage> {
  final List<AccountListItem> items = [];

  @override
  void initState() {
    super.initState();
    loadCards();
  }

  void loadCards() async {
    final accounts = widget.accountListViewModel.accounts;
    final styleSettings = await BalanceCardStyleSettings.getAll(
        widget.dashboardViewModel.wallet.walletInfo.internalId);

    items.clear();
    for (int i = 0; i < accounts.length; i++) {
      if (styleSettings.firstWhereOrNull((item) => item.accountIndex == i)?.hidden ?? false) {
        items.add(accounts[i]);
      }
    }
    setState(() {});
  }

  void unhideCard(AccountListItem acc) async {
    (await BalanceCardStyleSettings.get(
            widget.dashboardViewModel.wallet.walletInfo.internalId, acc.id))
        ?.copyWith(hidden: false)
        .insert();
    loadCards();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ModalTopBar(
            title: S.of(context).hidden_accounts,
            leadingIcon: Icon(Icons.arrow_back_ios_new),
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Expanded(
              child: items.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          S.of(context).no_hidden_accounts,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          S.of(context).no_hidden_accounts_desc,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        )
                      ],
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 36),
                      controller: ModalScrollController.of(context),
                      itemCount: items.length,
                      itemBuilder: (context, index) => HiddenBalanceCard(
                        item: items[index],
                        assetTtle: widget.dashboardViewModel.wallet.currency.title,
                        fiatAmount: ((double.tryParse(items[index].balance ?? "0") ?? 0) *
                                widget.dashboardViewModel.balanceViewModel.price)
                            .toStringAsFixed(2),
                        fiatCurrencyTitle:
                            widget.dashboardViewModel.settingsStore.fiatCurrency.title,
                        onRestorePressed: () => unhideCard(items[index]),
                      ),
                      separatorBuilder: (_, __) => SizedBox(height: 16),
                    )),
        ],
      ),
    );
  }
}

class HiddenBalanceCard extends StatelessWidget {
  const HiddenBalanceCard(
      {super.key,
      required this.item,
      required this.assetTtle,
      required this.fiatAmount,
      required this.fiatCurrencyTitle,
      required this.onRestorePressed});

  final AccountListItem item;
  final String assetTtle;
  final String fiatAmount;
  final String fiatCurrencyTitle;
  final VoidCallback onRestorePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(width: 2, color: Theme.of(context).colorScheme.surfaceContainerHigh)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  "#${item.id} ${item.label}",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                Row(
                  spacing: 8,
                  children: [
                    Text(
                      item.balance ?? "0",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 26,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(assetTtle,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 26,
                            fontWeight: FontWeight.w500))
                  ],
                ),
                Text(
                  "$fiatAmount $fiatCurrencyTitle",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(),
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(80085),
                  child: InkWell(
                    onTap: onRestorePressed,
                    borderRadius: BorderRadius.circular(69420),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        spacing: 6,
                        children: [
                          CakeImageWidget(
                            imageUrl: "assets/new-ui/restore.svg",
                            colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                          ),
                          Text(
                            S.of(context).restore,
                            style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
