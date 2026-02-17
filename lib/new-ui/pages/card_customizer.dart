import 'dart:async';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
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
  late final bool editEnabled;

  @override
  void initState() {
    super.initState();

    // wait for the bloc to load, then figure out if we should allow name editing.
    final bloc = context.read<CardCustomizerBloc>();
    late final StreamSubscription sub;
    sub = bloc.stream.listen((state) {
      if (state is! CardCustomizerNotLoaded) {
        editEnabled = state.accountName.isNotEmpty;
        sub.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CardCustomizerBloc, CardCustomizerState>(
      listenWhen: (previous, current) =>
      previous.accountName != current.accountName,
      listener: (context, state) {
        accountNameController.text = state.accountName;
      },
  child: BlocBuilder<CardCustomizerBloc, CardCustomizerState>(
      builder: (context, state) {
        if (state is CardCustomizerNotLoaded) return SizedBox.shrink();
        return PopScope(
          child: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                spacing: 25.0,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ModalTopBar(
                    title: editEnabled ? S.of(context).edit_account : S.of(context).edit_card,
                    leadingIcon: Icon(Icons.close),
                    trailingIcon: editEnabled ? Icon(Icons.delete_forever) : null,
                    onLeadingPressed: () => Navigator.of(context).maybePop(),
                    onTrailingPressed: () {},
                  ),
                  if (editEnabled)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Column(
                        spacing: 8.0,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(S.of(context).account_name),
                          TextField(
                            onChanged: (value) {
                              context.read<CardCustomizerBloc>().add(AccountNameChanged(value));
                            },
                            controller: accountNameController,
                          )
                        ],
                      ),
                    ),
                  BalanceCard(
                    width: MediaQuery.of(context).size.width * 0.87,
                    selected: true,
                    designSwitchDuration: Duration(milliseconds: 300),
                    accountName:
                    editEnabled ?  state.accountName:"" ,
                    balance: "0.00",
                    assetName: state.displaySats ? "sats" : widget.cryptoName,
                    capitalizeAssetName: !state.displaySats,
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
                                    Text(S.of(context).card_style),
                                    Container(
                                      height: 63,
                                      child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: state.availableDesigns.length,
                                          separatorBuilder: (context, index) {
                                            return SizedBox(width: 8.0);
                                          },
                                          itemBuilder: (context, index) {
                                            return GestureDetector(
                                              onTap: () {
                                                context
                                                    .read<CardCustomizerBloc>()
                                                    .add(CardDesignSelected(index));
                                              },
                                              child: AnimatedContainer(
                                                duration: Duration(milliseconds: 300),
                                                decoration: ShapeDecoration(
                                                  shape: RoundedSuperellipseBorder(
                                                    side: BorderSide(color: ((index == state.selectedDesignIndex )? Theme.of(context).colorScheme.onSurface : Colors.transparent), width: 1),
                                                    borderRadius: BorderRadiusGeometry.circular(12),
                                                  ),
                                                ),
                                                child: AnimatedScale(
                                                  duration: Duration(milliseconds: 200),
                                                  scale: index == state.selectedDesignIndex ? 0.94 : 1,
                                                  child: BalanceCard(
                                                    width: 96,
                                                    borderRadius: 10,
                                                    selected: false,
                                                    designSwitchDuration: Duration(milliseconds: 300),
                                                    design: state.availableDesigns[index],
                                                    gradient: state.selectedDesign.gradient,
                                                  ),
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
                                    Text(S.of(context).color),
                                    Container(
                                        width: double.infinity,
                                        child: Wrap(
                                          direction: Axis.horizontal,
                                          spacing: 4, // space between items in a row
                                          runSpacing: 8,
                                          children:
                                              List.generate(state.availableColors.length, (index) {
                                            return Material(
                                              borderRadius: BorderRadius.circular(999999999),
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(999999999),
                                                onTap: () {
                                                  context
                                                      .read<CardCustomizerBloc>()
                                                      .add(ColorSelected(index));
                                                },
                                                child: Stack(
                                                  children: [
                                                    AnimatedOpacity(
                                                      duration: Duration(milliseconds: 200),
                                                      opacity: index == state.selectedColorIndex ? 1 : 0,
                                                      child: Container(
                                                          width:32,height:32,decoration: BoxDecoration(borderRadius: BorderRadius.circular(99999999),border: Border.all(color:Theme.of(context)
                                                          .colorScheme
                                                          .onSurface))
                                                      ),
                                                    ),
                                                    AnimatedScale(
                                                      duration: Duration(milliseconds: 200),
                                                      scale: index == state.selectedColorIndex ? 0.8 : 1,
                                                      child: Container(
                                                        width: 32,
                                                        height: 32,
                                                        decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(99999999),
                                                            gradient: state.availableColors[index]),
                                                      ),
                                                    ),
                                                  ],
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
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 52),
                            ),
                            onPressed: Navigator.of(context).maybePop,
                            child: Text(
                              S.of(context).cancel,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: Theme.of(context).colorScheme.primary)),
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
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 52),
                            ),
                            onPressed: () {
                              context.read<CardCustomizerBloc>().add(DesignSaved());
                              Navigator.of(context).maybePop();
                            },
                            child: Text(
                              S.of(context).save,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    ),
);
  }

}
