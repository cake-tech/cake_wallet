import 'package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cw_core/card_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CardCustomizer extends StatefulWidget {
  const CardCustomizer({super.key, required this.cryptoTitle, required this.cryptoName});

  final String cryptoTitle;
  final String cryptoName;

  @override
  State<CardCustomizer> createState() => _CardCustomizerState();
}

class _CardCustomizerState extends State<CardCustomizer> {
  final accountNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    accountNameController.text = context.read<CardCustomizerBloc>().state.accountName;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CardCustomizerBloc, CardCustomizerState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: SafeArea(
            child: Column(
              spacing: 25.0,
              mainAxisSize: MainAxisSize.min,
              children: [
                ModalTopBar(
                  title: state.accountName.isEmpty ? "Edit Card" : "Edit Account",
                  leadingIcon: Icon(Icons.close),
                  trailingIcon: state.accountName.isEmpty ? null : Icon(Icons.delete_forever),
                  onLeadingPressed: () => Navigator.of(context).pop(),
                  onTrailingPressed: () {},
                ),
                if (state.accountName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
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
                  accountName:
                      state.accountName.isEmpty ? widget.cryptoTitle : accountNameController.text,
                  showBuyActions: false,
                  balance: "0.00",
                  assetName: widget.cryptoName,
                  design: state.selectedDesign,
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
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
                                    height: 63,
                                    child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: state.availableDesigns.length,
                                        separatorBuilder: (context, index) {
                                          return SizedBox(width: 8.0);
                                        },
                                        itemBuilder: (context, index) {
                                          return Material(
                                            borderRadius: BorderRadius.circular(16),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(16),
                                              onTap: () {
                                                context
                                                    .read<CardCustomizerBloc>()
                                                    .add(CardDesignSelected(index));
                                              },
                                              child: BalanceCard(
                                                width: 100,
                                                borderRadius: 10,
                                                selected: false,
                                                showBuyActions: false,
                                                design: state.availableDesigns[index],
                                              ),
                                            ),
                                          );
                                        }),
                                  ),
                                ],
                              )),
                          SizedBox(height: 8),
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
                                      width: double.infinity,
                                      child: Wrap(
                                        direction: Axis.horizontal,
                                        spacing: 4, // space between items in a row
                                        runSpacing: 8,
                                        children:
                                            List.generate(CardDesign.allGradients.length, (index) {
                                          return Material(
                                            borderRadius: BorderRadius.circular(999999999),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(999999999),
                                              onTap: () {
                                                context
                                                    .read<CardCustomizerBloc>()
                                                    .add(ColorSelected(index));
                                              },
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(99999999),
                                                    border: Border.all(
                                                        color: state.selectedColorIndex == index
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .onSurface
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .surfaceContainerHigh,
                                                        width: 2),
                                                    gradient: CardDesign.allGradients[index]),
                                              ),
                                            ),
                                          );
                                        }),
                                      )),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    )),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
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
                            context.read<CardCustomizerBloc>().add(DesignSaved());
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
          ),
        );
      },
    );
  }

}
