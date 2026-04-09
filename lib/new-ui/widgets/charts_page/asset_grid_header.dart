import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/long_press_menu/long_press_popup.dart';
import 'package:cake_wallet/new-ui/model/charts/util/price_data_sort_criteria.dart';
import 'package:cake_wallet/new-ui/viewmodels/charts/charts_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/long_press_menu/long_press_menu.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChartsAssetGridHeader extends StatelessWidget {
  const ChartsAssetGridHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChartsBloc, ChartsState>(
      builder: (context, state) {
        final bloc = context.read<ChartsBloc>();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context).followed_assets,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
            Row(
              spacing: 8,
              children: [
                ModernButton.svg(
                  size: 36,
                  iconSize: 16,
                  svgPath: "assets/new-ui/add.svg",
                  onPressed: () => _showCurrencyPicker(context, bloc),
                ),
                LongPressPopupBuilder(
                    showOnTap: true,
                    popup: LongPressMenu(
                        items: PriceDataSortCriterium.all.map((item) {
                      final isSelected =
                          state is ChartsStateWithData && state.sortCriterium == item;

                      return LongPressMenuItem(
                          label: item.name,
                          iconPath: item.iconPath,
                          color: isSelected ? Theme.of(context).colorScheme.primary : null,
                          onSelected: () {
                            bloc.add(SortingCriteriumChanged(newCriterium: item));
                            Navigator.of(context).pop();
                          });
                    }).toList()),
                    child: ModernButton.svg(
                      size: 36,
                      iconSize: 12,
                      svgPath: "assets/new-ui/sort.svg",
                      onPressed: () {},
                    ))
              ],
            )
          ],
        );
      },
    );
  }

  void _showCurrencyPicker(BuildContext context, ChartsBloc bloc) {
    showPopUp(
        context: context,
        builder: (context) => CurrencyPicker(
            selectedAtIndex: -1,
            items: CryptoCurrency.all,
            onItemSelected: (item) {
              if (item is CryptoCurrency) {
                bloc.add(CurrencyAdded(currency: item));
              }
            }));
  }
}
