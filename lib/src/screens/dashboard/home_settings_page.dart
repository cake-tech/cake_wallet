import 'dart:math';

import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/entities/sort_balance_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
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
          Observer(
            builder: (_) => SettingsPickerCell<SortBalanceBy>(
              title: S.current.sort_by,
              items: SortBalanceBy.values,
              selectedItem: _homeSettingsViewModel.sortBalanceBy,
              onItemSelected: _homeSettingsViewModel.setSortBalanceBy,
            ),
          ),
          Divider(color: Theme.of(context).colorScheme.outlineVariant),
          Observer(
            builder: (_) => SettingsSwitcherCell(
              title: S.of(context).pin_at_top(_homeSettingsViewModel.nativeToken.title),
              value: _homeSettingsViewModel.pinNativeToken,
              onValueChange: (_, bool value) {
                _homeSettingsViewModel.setPinNativeToken(value);
              },
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
                          leading: Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(shape: BoxShape.circle),
                            child: CakeImageWidget(
                              imageUrl: token.iconPath,
                              height: 40,
                              width: 40,
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
