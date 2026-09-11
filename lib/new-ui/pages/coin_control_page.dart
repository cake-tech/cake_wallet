import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/coin_control/coin_control_bloc.dart";
import "package:cake_wallet/new-ui/widgets/coin_control_page/coin_control_list_item.dart";
import "package:cake_wallet/new-ui/widgets/modal_header.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/coin_control/coin_selection.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class CoinControlPageArgs {
  const CoinControlPageArgs({
    required this.canEdit,
    this.coinTypeToSpendFrom,
    this.initialSelection,
  });

  final bool canEdit;
  final UnspentCoinType? coinTypeToSpendFrom;
  final CoinSelection? initialSelection;
}

class NewCoinControlPage extends StatelessWidget {
  const NewCoinControlPage({
    required this.bloc,
    required this.canEdit,
    required this.fiatConversionStore,
    required this.fiatCurrency,
    required this.isFiatDisabled,
    super.key,
  });

  final CoinControlBloc bloc;
  final bool canEdit;
  final FiatConversionStore fiatConversionStore;
  final FiatCurrency fiatCurrency;
  final bool isFiatDisabled;

  @override
  Widget build(BuildContext context) => BlocProvider.value(
      value: bloc,
      child: BlocListener<CoinControlBloc, CoinControlState>(
        listenWhen: (_, state) => state is CoinControlSaved,
        listener: (context, state) =>
            Navigator.of(context).pop((state as CoinControlSaved).selection),
        child: Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Column(
              children: [
                BlocBuilder<CoinControlBloc, CoinControlState>(
                  builder: (context, state) => ModalTopBar(
                      title: "",
                      trailingWidget: GestureDetector(
                        onTap: () {
                                if (!canEdit) {
                                  Navigator.of(context).pop();
                                  return;
                                }
                                context.read<CoinControlBloc>().add(const SelectionSaved());
                              },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(99999)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Text(
                              S.of(context).done,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,),
                            ),
                          ),
                        ),
                      ),
                    ),
                ),
                BlocBuilder<CoinControlBloc, CoinControlState>(builder: (context, state) {
                  if (state is CoinControlLoading) {
                    return Expanded(
                      child: Center(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 12,
                        children: [
                          const CupertinoActivityIndicator(),
                          Text("${S.of(context).loading}...")
                        ],
                      )),
                    );
                  }

                  if (state is CoinControlFailure) {
                    return Center(child: Text(S.of(context).coin_control_load_failed));
                  }

                  return Expanded(
                    child: SingleChildScrollView(
                      child: SafeArea(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18.0),
                              child: ModalHeader(
                                  iconPath: "assets/new-ui/settings_row_icons/coin-control.svg",
                                  title: "Coin Control",
                                  message: canEdit
                                      ? S.of(context).coin_control_desc
                                      : S.of(context).coin_control_desc_no_edit),
                            ),
                            if(state is CoinControlLoaded) ...[
                              if (state.rows.isNotEmpty && canEdit)
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    spacing: 20,
                                    children: [
                                      GestureDetector(
                                        onTap: () => context
                                            .read<CoinControlBloc>()
                                            .add(SelectAllChanged(value: true)),
                                        child: Text(S.of(context).select_all,
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400)),
                                      ),
                                      GestureDetector(
                                        onTap: () => context
                                            .read<CoinControlBloc>()
                                            .add(SelectAllChanged(value: false)),
                                        child: Text(S.of(context).unselect_all,
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400)),
                                      )
                                    ],
                                  ),
                                )
                              else
                                SizedBox(
                                  height: 24,
                                ),
                              if (state.rows.isEmpty) ...[
                                SizedBox(height: 12),
                                Center(
                                    child: Text(
                                      S.of(context).no_unspent_coins,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    )),
                              ],
                              if (state.selectable.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                                  child: CoinControlListSection(
                                    rows: state.selectable,
                                    canEdit: canEdit,
                                    fiatConversionStore: bloc.fiatConversionStore,
                                  ),
                                ),
                              if (state.frozen.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                                  child: Column(
                                      spacing: 10,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 12),
                                        Text(
                                          S.of(context).frozen,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant),
                                        ),
                                        CoinControlListSection(
                                          rows: state.frozen,
                                          canEdit: canEdit,
                                          fiatConversionStore: bloc.fiatConversionStore,
                                        ),
                                      ]),
                                ),
                              const SizedBox(height: 12)
                            ]
                          ],
                        ),
                      ),
                    ),
                  );
                })
              ],
            ),
          ),
        ),
      ),
    );


}

class CoinControlListSection extends StatelessWidget {
  const CoinControlListSection({
    super.key,
    required this.rows,
    required this.canEdit,
    required this.fiatConversionStore,
  });

  final List<CoinRow> rows;
  final bool canEdit;
  final FiatConversionStore fiatConversionStore;

  @override
  Widget build(BuildContext context) => ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, __) => Container(
        height: 1,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      itemBuilder: (_, index) {
        final row = rows[index];

        return GestureDetector(
          onTap: () => Navigator.of(context).pushNamed(
            Routes.unspentCoinsDetails,
            arguments: [row.id, context.read<CoinControlBloc>()],
          ),
          child: CoinControlListItem(
            note: row.note,
            amount: row.amount.toStringWithSymbol(),
            fiatAmount: fiatConversionStore
                  .convertSync(row.amount, getIt.get<SettingsStore>().fiatCurrency)?.toStringWithSymbol(trimZeros: false) ?? "",
              address: row.address,
            isSending: row.isSelected,
            isFrozen: row.isFrozen,
            isChange: row.isChange,
            isSilentPayment: row.isSilentPayment,
            isLoading: false,
            isFirst: index == 0,
            isLast: index == rows.length - 1,
            hasCheckbox: canEdit,
            onCheckBoxTap: () => context
                .read<CoinControlBloc>()
                .add(SelectionChanged(row.id, value: !row.isSelected)),
          ),
        );
      },
    );
}
