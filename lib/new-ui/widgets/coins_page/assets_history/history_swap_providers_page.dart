import "package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/transaction_history/transaction_history_bloc.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/select_deselect_all.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class HistorySwapProvidersPage extends StatelessWidget {
  const HistorySwapProvidersPage({ required this.bloc, required this.parentKey, super.key,});

  final TransactionHistoryBloc bloc;
  final String parentKey;

  @override
  Widget build(BuildContext context) => ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ModalTopBar(
            title: S.of(context).swap_providers,
            leadingIcon: const Icon(Icons.arrow_back_ios_new),
            leadingSemanticLabel: S.of(context).seed_alert_back,
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: ModalScrollController.of(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: BlocBuilder<TransactionHistoryBloc, TransactionHistoryState>(
                  bloc: bloc,
                  builder: (context, _) {
                    final parent = bloc.filters.firstWhere((filter) => filter.key == parentKey);

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: SelectDeselectAllBar(
                              title: S.of(context).swap_providers,
                              onSelected: (value) => bloc.add(
                                TransactionHistoryFiltersSet(
                                  parent.children,
                                  value: value,
                                ),
                              ),
                            ),
                          ),
                        ),
                        NewListSections(sections: {
                          "": [
                            for (final child in parent.children)
                              ListItemCheckbox(
                                iconPath: child.iconPath,
                                keyValue: child.key,
                                label: S.of(context).getByKey(child.caption),
                                value: child.value,
                                onChanged: (_) =>
                                    bloc.add(TransactionHistoryFilterToggled(child)),
                              ),
                          ],
                        },),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
}
