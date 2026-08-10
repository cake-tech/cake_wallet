import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/monero_account_list/account_list_item.dart";
import "package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart";
import "package:cw_core/balance_card_layout.dart";
import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/crypto_amount_format.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class HiddenAccountsPage extends StatefulWidget {
  const HiddenAccountsPage(
      {required this.accountListViewModel, required this.dashboardViewModel, super.key,});

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

  int get _walletInfoId => widget.dashboardViewModel.wallet.walletInfo.internalId;

  Future<BalanceCardLayout> _layout() async => BalanceCardLayout.resolve(
        accountIndices:
            widget.accountListViewModel.accounts.map((account) => account.id).toList(),
        settings: await BalanceCardStyleSettings.getAll(_walletInfoId),
      );

  Future<void> loadCards() async {
    final accounts = widget.accountListViewModel.accounts;
    final layout = await _layout();

    items.clear();
    for (final accountIndex in layout.hidden) {
      final account = accounts.firstWhereOrNull((account) => account.id == accountIndex);
      if (account != null) {
        items.add(account);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _fiatAmount(AccountListItem item) =>
      ((double.tryParse(item.balance ?? "0") ?? 0) * widget.dashboardViewModel.balanceViewModel.price)
          .toStringAsFixed(2);

  Future<void> unhideCard(AccountListItem acc) async {
    final restored = (await _layout()).unhiding(acc.id);
    await BalanceCardStyleSettings.setVisibleOrder(_walletInfoId, restored.orders);

    await loadCards();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ModalTopBar(
            leadingSemanticLabel: S.of(context).seed_alert_back,
            title: S.of(context).hidden_accounts,
            leadingIcon: const Icon(Icons.arrow_back_ios_new),
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Expanded(
              child: items.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          S.of(context).no_hidden_accounts,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            softWrap: false,
                            S.of(context).no_hidden_accounts_desc,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      controller: ModalScrollController.of(context),
                      itemCount: items.length,
                      itemBuilder: (context, index) => HiddenBalanceCard(
                        item: items[index],
                        assetTtle: widget.dashboardViewModel.wallet.currency.title,
                        fiatAmount: _fiatAmount(items[index]),
                        fiatCurrencyTitle:
                            widget.dashboardViewModel.settingsStore.fiatCurrency.title,
                        onRestorePressed: () => unhideCard(items[index]),
                      ),
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                    ),),
        ],
      ),
    );
}

class HiddenBalanceCard extends StatelessWidget {
  const HiddenBalanceCard(
      {required this.item, required this.assetTtle, required this.fiatAmount, required this.fiatCurrencyTitle, required this.onRestorePressed, super.key,});

  final AccountListItem item;
  final String assetTtle;
  final String fiatAmount;
  final String fiatCurrencyTitle;
  final VoidCallback onRestorePressed;

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(width: 2, color: Theme.of(context).colorScheme.surfaceContainerHigh),),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                      fontWeight: FontWeight.w500,),
                ),
                Row(
                  spacing: 8,
                  children: [
                    Text(
                      item.balance?.withMaxDecimals(8) ?? "0",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 26,
                          fontWeight: FontWeight.w500,),
                    ),
                    Text(assetTtle,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 26,
                            fontWeight: FontWeight.w500,),),
                  ],
                ),
                Text(
                  "$fiatAmount $fiatCurrencyTitle",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16,),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(),
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(80085),
                  child: InkWell(
                    onTap: onRestorePressed,
                    borderRadius: BorderRadius.circular(69420),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        spacing: 6,
                        children: [
                          CakeImageWidget(
                            imageUrl: "assets/new-ui/restore.svg",
                            colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.primary, BlendMode.srcIn,),
                          ),
                          Text(
                            S.of(context).restore,
                            style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
}
