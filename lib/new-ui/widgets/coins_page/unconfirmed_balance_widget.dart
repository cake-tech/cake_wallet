import 'package:cake_wallet/generated/i18n.dart';
import "package:cake_wallet/new-ui/widgets/coins_page/zcash_migration_modal.dart";
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import "package:flutter/cupertino.dart";
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class UnconfirmedBalanceWidget extends StatelessWidget {
  const UnconfirmedBalanceWidget({
    super.key,
    required this.dashboardViewModel,
  });

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    final currency = dashboardViewModel.wallet.currency;
    return Observer(builder: (_) {
      final show = dashboardViewModel.balanceViewModel
          .hasAdditionalBalance(dashboardViewModel.wallet.currency);
      final isIronwoodMigration = dashboardViewModel.isMigratingToIronwood;

      return AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: show
            ? Column(
                children: [
                  const SizedBox(height: 12, width: double.infinity),
                  Observer(builder: (context) {
                    final balance = dashboardViewModel.balanceViewModel.additionalBalance(currency);

                    return Container(
                      width: MediaQuery.of(context).size.width * 0.87,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final modal = isIronwoodMigration
                                ? ZcashMigrationModal(
                                    hasContinue: false, balance: "${balance} ${currency.symbol}")
                                : UnconfirmedBalanceModal(
                                    balance: balance.toStringWithSymbol(),
                              currencyIconPath: currency.iconPath ?? "",
                            );
                            showMaterialModalBottomSheet(
                                backgroundColor: Colors.transparent,
                                context: context,
                                builder: (context) => modal);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  spacing: 12,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: isIronwoodMigration
                                          ? CupertinoActivityIndicator(
                                              color: Theme.of(context).colorScheme.primary,
                                            )
                                          : CircularProgressIndicator(
                                              strokeWidth: 2,
                                        backgroundColor:
                                            Theme.of(context).colorScheme.primary.withAlpha(50),
                                        color: Theme.of(context).colorScheme.primary,
                                        value: dashboardViewModel.confirmationProgress,
                                      ),
                                    ),
                                    Row(
                                      spacing: 4,
                                      children: [
                                        Text(
                                          "$balance ${currency.title}",
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                        Text(isIronwoodMigration ? S.of(context).migrating_to_ironwood : S.of(context).confirming),
                                      ],
                                    )
                                  ],
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              )
            : const SizedBox(width: double.infinity),
      );
    });
  }
}

class UnconfirmedBalanceModal extends StatelessWidget {
  const UnconfirmedBalanceModal({super.key, required this.balance, required this.currencyIconPath});

  final String balance;
  final String currencyIconPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 20,
          children: [
            ModalTopBar(
                title: S.of(context).balance_confirmation,
                leadingIcon: Icon(Icons.close),
                leadingSemanticLabel: S.of(context).close,
                onLeadingPressed: Navigator.of(context).pop),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                spacing: 20,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CakeImageWidget(imageUrl: currencyIconPath, height: 100, width: 100),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            border:
                                Border.all(color: Theme.of(context).colorScheme.surface, width: 3),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white),
                        child: Icon(
                          Icons.lock_outlined,
                          size: 24,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${balance} ${S.of(context).balance_confirmation_desc_1}\n\n${S.of(context).balance_confirmation_desc_2}\n\n${S.of(context).balance_confirmation_desc_3}",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  NewPrimaryButton(
                      onPressed: Navigator.of(context).pop,
                      text: S.of(context).close,
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary),
                  SizedBox(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

