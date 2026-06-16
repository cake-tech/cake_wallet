import 'dart:math';

import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart';
import 'package:cake_wallet/entities/sort_balance_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/favorite_token_modal.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/view_model/dashboard/home_settings_view_model.dart';

class HomeSettingsPage extends BasePage {
  HomeSettingsPage(this._homeSettingsViewModel);

  final HomeSettingsViewModel _homeSettingsViewModel;

  final TextEditingController _searchController = TextEditingController();

  @override
  String? get title => S.current.home_screen_settings;

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Observer(
          //   builder: (_) => SettingsPickerCell<SortBalanceBy>(
          //     title: S.current.sort_by,
          //     items: SortBalanceBy.values,
          //     selectedItem: _homeSettingsViewModel.sortBalanceBy,
          //     onItemSelected: _homeSettingsViewModel.setSortBalanceBy,
          //   ),
          // ),
          // Divider(color: Theme.of(context).colorScheme.outlineVariant),
          // Observer(
          //   builder: (_) => SettingsSwitcherCell(
          //     title: S.of(context).show_combined_balance,
          //     value: _homeSettingsViewModel.showCombinedBalance,
          //     onValueChange: (_, bool value) {
          //       _homeSettingsViewModel.setShowCombinedBalance(value);
          //     },
          //   ),
          // ),
          // Observer(
          //     builder: (_) => _homeSettingsViewModel.showCombinedBalance
          //         ? SizedBox.shrink()
          //         : SettingsCellWithArrow(
          //             title: S.of(context).favorite_token,
          //             handler: (context) async {
          //
          //             },
          //           )),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Observer(
              builder: (_) => NewListSections(sections: {
                "": [
                  ListItemRegularRow(
                      keyValue: "sort balance by",
                      label: S.of(context).sort_by,
                      trailingText: _homeSettingsViewModel.sortBalanceBy.toString(),
                      onTap: () {
                        showPopUp<void>(
                          context: context,
                          builder: (context) => Picker(
                            items: SortBalanceBy.values,
                            selectedAtIndex:
                                SortBalanceBy.values.indexOf(_homeSettingsViewModel.sortBalanceBy),
                            mainAxisAlignment: MainAxisAlignment.start,
                            onItemSelected: _homeSettingsViewModel.setSortBalanceBy,
                            isSeparated: false,
                          ),
                        );
                      }),
                  ListItemToggle(
                      keyValue: "show combined",
                      label: S.of(context).show_combined_balance,
                      value: _homeSettingsViewModel.showCombinedBalance,
                      onChanged: (val) => _homeSettingsViewModel.setShowCombinedBalance(val)),
                  if (!_homeSettingsViewModel.showCombinedBalance)
                    ListItemRegularRow(
                        keyValue: "fav token",
                        label: S.of(context).favorite_token,
                        trailingText: _homeSettingsViewModel.favoriteToken.title,
                        showArrow: true,
                        onTap: () async {
                          final res = await showModalBottomSheet(
                              context: context,
                              builder: (context) =>
                                  FavoriteTokenModal(tokens: _homeSettingsViewModel.enabledTokens));
                          if (res != null && res is CryptoCurrency) {
                            _homeSettingsViewModel.setFavoriteToken(res);
                          }
                        })
                ]
              }),
            ),
          ),
          Divider(color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16),
                  child: BaseTextFormField(
                    controller: _searchController,
                    textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    hintText: S.of(context).search_add_token,
                    prefixIcon: Image.asset(
                      "assets/images/search_icon.png",
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    alignLabelWithHint: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    onChanged: (String text) => _homeSettingsViewModel.changeSearchText(text),
                  ),
                ),
              ),
              RawMaterialButton(
                onPressed: () async {
                  Navigator.pushNamed(
                    context,
                    Routes.editToken,
                    arguments: {
                      'homeSettingsViewModel': _homeSettingsViewModel,
                      if (AddressValidator(type: _homeSettingsViewModel.nativeToken)
                          .isValid(_searchController.text))
                        'contractAddress': _searchController.text,
                    },
                  );
                },
                elevation: 0,
                fillColor: Theme.of(context).colorScheme.surfaceContainer,
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 22.0,
                ),
                padding: EdgeInsets.all(12),
                shape: CircleBorder(),
                splashColor: Theme.of(context).colorScheme.surfaceContainer,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            child: Observer(
              builder: (_) => ListView.builder(
                itemCount: _homeSettingsViewModel.tokens.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(top: 16),
                    child: Observer(
                      builder: (_) {
                        final token = _homeSettingsViewModel.tokens.elementAt(index);

                        return SettingsSwitcherCell(
                          title: "${token.name} "
                              "(${token.title})",
                          value: token.enabled,
                          onValueChange: (_, bool value) {
                            _homeSettingsViewModel.changeTokenAvailability(token, value);
                          },
                          onTap: (_) {
                            Navigator.pushNamed(context, Routes.editToken, arguments: {
                              'homeSettingsViewModel': _homeSettingsViewModel,
                              'token': token,
                            });
                          },
                          leading: TokenImageWidget(
                            imageUrl: token.iconPath ?? '',
                            size: 40,
                            errorWidget: Container(
                              height: 30.0,
                              width: 30.0,
                              child: Center(
                                child: Text(
                                  token.title.substring(0, min(token.title.length, 2)),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(30),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
