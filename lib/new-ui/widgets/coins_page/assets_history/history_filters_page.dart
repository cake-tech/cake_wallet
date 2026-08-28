import 'package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/viewmodels/transaction_history/transaction_history_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_swap_providers_page.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/select_deselect_all.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cw_core/history_filter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class HistoryFiltersPage extends StatelessWidget {
  const HistoryFiltersPage({super.key, required this.bloc});

  final TransactionHistoryBloc bloc;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ModalTopBar(
            title: S.of(context).filters,
            leadingIcon: Icon(Icons.arrow_back_ios_new),
            leadingSemanticLabel: S.of(context).seed_alert_back,
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: ModalScrollController.of(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: BlocBuilder<TransactionHistoryBloc, TransactionHistoryState>(
                  bloc: bloc,
                  builder: (context, _) => Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
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
                          "": [
                            for (final filter in bloc.filters) _row(context, filter),
                          ],
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
              padding: const EdgeInsets.all(18.0),
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
  }

  ListItem _row(BuildContext context, HistoryFilter filter) {
    final label = S.of(context).getByKey(filter.caption);

    if (!filter.hasChildren) {
      return ListItemCheckbox(
        iconPath: filter.iconPath,
        keyValue: filter.key,
        label: label,
        value: filter.value,
        onChanged: (_) => bloc.add(TransactionHistoryFilterToggled(filter)),
      );
    }

    final (subtitle, subtitleColor) = _childSummary(context, filter);

    return ListItemCheckbox(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => HistorySwapProvidersPage(bloc: bloc, parentKey: filter.key),
        ),
      ),
      keyValue: filter.key,
      label: label,
      value: filter.value,
      onChanged: (_) => bloc.add(TransactionHistoryFilterToggled(filter)),
      subtitle: subtitle,
      subtitleColor: subtitleColor,
      showArrow: true,
    );
  }

  (String, Color) _childSummary(BuildContext context, HistoryFilter filter) {
    final enabled = filter.enabledChildren;

    if (enabled == filter.children.length) {
      return (S.of(context).manage_providers, Theme.of(context).colorScheme.onSurfaceVariant);
    }

    if (enabled == 0) {
      return (S.of(context).no_providers_selected, const Color(0xFFFFB84E));
    }

    return ("$enabled ${S.of(context).providers}", Theme.of(context).colorScheme.primary);
  }
}
