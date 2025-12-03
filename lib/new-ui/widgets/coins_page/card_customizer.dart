import 'package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:cw_core/card_design.dart';
import 'package:flutter/material.dart';

class CardCustomizer extends StatefulWidget {
  const CardCustomizer({super.key, required this.dashboardViewModel, this.accountListViewModel});

  final DashboardViewModel dashboardViewModel;
  final MoneroAccountListViewModel? accountListViewModel;

  @override
  State<CardCustomizer> createState() => _CardCustomizerState();
}

class _CardCustomizerState extends State<CardCustomizer> {
  final accountNameController = TextEditingController();
  List<CardDesign> availableDesigns = List<CardDesign>.empty(growable: true);
  int _selectedDesignIndex = 0;
  int _selectedColorIndex = 0;

  @override
  void initState() {
    super.initState();

    final selectedAccount = widget.accountListViewModel?.accounts.where((e) => e.isSelected).first;
    final accountIndex = selectedAccount == null
        ? 0
        : widget.accountListViewModel!.accounts.indexOf(selectedAccount);

    accountNameController.text = selectedAccount?.label ?? "";

    final currentDesign = widget.dashboardViewModel.cardDesigns[accountIndex];

    final currency = widget.dashboardViewModel.wallet.currency;
    availableDesigns.add(CardDesign.forCurrency(currency));
    if (currentDesign.backgroundType == CardDesignBackgroundTypes.svgIcon) {
      _selectedDesignIndex = 0;
    }

    if (CardDesign.specialDesignsForCurrencies[currency] != null) {
      availableDesigns.add(CardDesign.forCurrencySpecial(currency));
    }
    if (currentDesign.backgroundType == CardDesignBackgroundTypes.svgFull) {
      _selectedDesignIndex = 1;
    }

    _selectedColorIndex = CardDesign.allGradients.indexOf(currentDesign.gradient);
    if (_selectedColorIndex == -1) {
      _selectedColorIndex =
          CardDesign.allGradients.indexOf(CardDesign.forCurrency(currency).gradient);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.accountListViewModel?.accounts.where((e) => e.isSelected).first;

    CardDesign selectedDesign = availableDesigns[_selectedDesignIndex];
    if (selectedDesign.backgroundType == CardDesignBackgroundTypes.svgIcon) {
      selectedDesign = selectedDesign.withGradient(CardDesign.allGradients[_selectedColorIndex]);
    }

    return SafeArea(
      child: Column(
        spacing: 25.0,
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalTopBar(
            title: widget.accountListViewModel == null ? "Edit Card" : "Edit Account",
            leadingIcon: Icon(Icons.close),
            trailingIcon: widget.accountListViewModel == null ? null : Icon(Icons.delete_forever),
            onLeadingPressed: () => Navigator.of(context).pop(),
            onTrailingPressed: () {},
          ),
          if (widget.accountListViewModel != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                spacing: 8.0,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Account name"),
                  TextField(
                    controller: accountNameController,
                  )
                ],
              ),
            ),
          BalanceCard(
            width: MediaQuery.of(context).size.width * 0.9,
            selected: true,
            accountName: account?.label ??
                widget.dashboardViewModel.wallet.currency.fullName ??
                widget.dashboardViewModel.wallet.currency.title,
            accountBalance: "",
            showBuyActions: false,
            balance:
                widget.dashboardViewModel.balanceViewModel.formattedBalances[0].availableBalance,
            fiatBalance: widget
                .dashboardViewModel.balanceViewModel.formattedBalances[0].fiatAvailableBalance,
            assetName: widget.dashboardViewModel.wallet.currency.name,
            design: selectedDesign,
          ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          spacing: 8.0,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Card style"),
                            Container(
                              height: 90,
                              child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: availableDesigns.length,
                                  separatorBuilder: (context, index) {
                                    return SizedBox(width: 8.0);
                                  },
                                  itemBuilder: (context, index) {
                                    return Material(
                                      borderRadius: BorderRadius.circular(16),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          setState(() {
                                            _selectedDesignIndex = index;
                                          });
                                        },
                                        child: BalanceCard(
                                          width: 140,
                                          selected: false,
                                          showBuyActions: false,
                                          design: availableDesigns[index],
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                          ],
                        )),
                    Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          spacing: 8.0,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Color"),
                            Container(
                              height: 32,
                              child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: CardDesign.allGradients.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                      child: Material(
                                        borderRadius: BorderRadius.circular(999999999),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(999999999),
                                          onTap: () {
                                            setState(() {
                                              _selectedColorIndex = index;
                                            });
                                          },
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(99999999),
                                                border: Border.all(
                                                    color: _selectedColorIndex == index
                                                        ? Theme.of(context).colorScheme.onSurface
                                                        : Theme.of(context).colorScheme.surfaceContainerHigh,
                                                    width: 1.5),
                                                gradient: CardDesign.allGradients[index]),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 60),
                    ),
                    onPressed: Navigator.of(context).pop,
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 60),
                    ),
                    onPressed: () {
                      saveDesign(selectedDesign);
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void saveDesign(CardDesign design) {
    final selectedAccountIndex =
        widget.accountListViewModel?.accounts.indexWhere((e) => e.isSelected) ?? 0;

    widget.dashboardViewModel.cardDesigns[selectedAccountIndex] = design;
    widget.dashboardViewModel.saveCardDesigns();
  }
}
