import "package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/transaction_history/transaction_history_bloc.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_swap_providers_page.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/select_deselect_all.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cw_core/history_filter.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class HistoryFiltersPage extends StatelessWidget {
  const HistoryFiltersPage({required this.bloc, super.key});

  final TransactionHistoryBloc bloc;

  @override
  Widget build(BuildContext context) => ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ModalTopBar(
            title: S.of(context).filters,
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
                  builder: (context, _) => Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: SelectDeselectAllBar(
                            title: S.of(context).type,
                            onSelected: (value) => bloc
                                .add(TransactionHistoryAllFiltersToggled(value: value)),
                          ),
                        ),
                      ),
                      NewListSections(
                        sections: {
                          "": bloc.filters.map((filter)=>ListItemCheckbox(
                            onTap: filter.hasChildren ? () => Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) => HistorySwapProvidersPage(bloc: bloc, parentKey: filter.key),
                              ),
                            ) : null,
                            keyValue: filter.key,
                            label: S.of(context).getByKey(filter.caption),
                            value: filter.value,
                            iconPath: filter.iconPath,
                            onChanged: (_) => bloc.add(TransactionHistoryFilterToggled(filter)),
                            subtitle: _subtitle(context, filter),
                            subtitleColor: _subtitleColor(context, filter),
                            showArrow: filter.hasChildren,
                          ),).toList(),
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: NewPrimaryButton(
                onPressed: () =>
                    bloc.add(const TransactionHistoryAllFiltersToggled(value: true)),
                text: S.of(context).reset_filters,
                color: Theme.of(context).colorScheme.surfaceContainer,
                textColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );

  String? _subtitle(BuildContext context, HistoryFilter filter) {
    if(!filter.hasChildren) {
      return null;
    }

    final enabled = filter.enabledChildren;

    if (enabled == filter.children.length) {
      return S.of(context).manage_providers;
    }

    if (enabled == 0) {
      return S.of(context).no_providers_selected;
    }

    return "$enabled ${S.of(context).providers}";
  }

  Color _subtitleColor(BuildContext context, HistoryFilter filter) {

    final enabled = filter.enabledChildren;

    if (enabled == filter.children.length) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }

    if (enabled == 0) {
      return const Color(0xFFFFB84E);
    }

    return Theme.of(context).colorScheme.primary;
  }
}
