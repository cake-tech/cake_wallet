import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart';
import 'package:cake_wallet/generated/i18n.dart';
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import "package:cake_wallet/src/screens/dashboard/favorite_token_page.dart";
import "package:cake_wallet/src/screens/dashboard/sort_balance_by_page.dart";
import "package:cake_wallet/src/screens/dashboard/token_list_page.dart";
import "package:cake_wallet/src/screens/dashboard/widgets/token_list_section.dart";
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cw_core/crypto_currency.dart';
import "package:flutter/cupertino.dart";
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/view_model/dashboard/home_settings_view_model.dart';

class HomeSettingsPage extends BasePage {
  HomeSettingsPage(this._homeSettingsViewModel);

  final HomeSettingsViewModel _homeSettingsViewModel;

  @override
  String? get title => S.current.manage_assets;

  @override
  Widget body(BuildContext context) => _HomeSettingsPageBody(_homeSettingsViewModel);
}

class _HomeSettingsPageBody extends StatefulWidget {
  const _HomeSettingsPageBody(this.viewModel);

  final HomeSettingsViewModel viewModel;

  @override
  State<_HomeSettingsPageBody> createState() => _HomeSettingsPageBodyState();
}

class _HomeSettingsPageBodyState extends State<_HomeSettingsPageBody> {
  final TextEditingController _searchController = TextEditingController();

  HomeSettingsViewModel get _homeSettingsViewModel => widget.viewModel;

  @override
  void dispose() {
    _searchController.dispose();
    _homeSettingsViewModel.dispose();
    super.dispose();
  }

  Future<void> _push(Widget page) =>
      Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => page));

  Future<void> _openSeeAll(String title, List<CryptoCurrency> Function() tokens) async {
    await _push(TokenListPage(_homeSettingsViewModel, title: title, tokens: tokens));
    _homeSettingsViewModel.clearToggledOff();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Observer(
              builder: (_) => NewListSections(sections: {
                "": [
                  ListItemRegularRow(
                      keyValue: "sort balance by",
                      label: S.of(context).sort_by,
                      trailingText: _homeSettingsViewModel.sortBalanceBy.toString(),
                      onTap: () => _push(SortBalanceByPage(_homeSettingsViewModel))),
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
                        onTap: () => _push(FavoriteTokenPage(_homeSettingsViewModel)))
                ]
              }),
            ),
          ),
          Divider(indent: 16, endIndent: 16, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: BaseTextFormField(
                      controller: _searchController,
                      textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12.8),
                      placeholderTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12.8,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      hintText: S.of(context).search,
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      prefixIconConstraints: const BoxConstraints.tightFor(width: 44, height: 36),
                      isDense: true,
                      contentPadding: const EdgeInsetsDirectional.only(end: 16),
                    ),
                  ),
                ),
                ModernButton(
                  size: 36,
                  icon: const Icon(Icons.add),
                  semanticLabel: S.of(context).add_token,
                  onPressed: () {
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
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (_, search, __) => Observer(
                builder: (_) {
                  if (search.text.trim().isNotEmpty) {
                    return TokenListSection(
                      viewModel: _homeSettingsViewModel,
                      tokens: _homeSettingsViewModel.tokens
                          .where(
                            (token) => _homeSettingsViewModel.matchesSearch(token, search.text),
                          )
                          .toList(),
                    );
                  }

                  final sections = _homeSettingsViewModel.tokenSections;
                  final visiblePopular = _homeSettingsViewModel.visibleSection(sections.popular);
                  final visibleOther = _homeSettingsViewModel.visibleSection(sections.other);
                  final hasHiddenFlaggedHoldings =
                      sections.holdings.any((token) => token.isPotentialScam && !token.enabled);

                  return Column(
                    spacing: 24,
                    children: [
                      if (_homeSettingsViewModel.isLoadingTokenBalances)
                        const CupertinoActivityIndicator(),
                      if (sections.holdings.isNotEmpty)
                        TokenListSection(
                          viewModel: _homeSettingsViewModel,
                          title: S.of(context).holdings,
                          tokens: sections.holdings,
                          footer: hasHiddenFlaggedHoldings ? const FlaggedTokensNote() : null,
                        ),
                      if (sections.popular.isNotEmpty)
                        TokenListSection(
                          viewModel: _homeSettingsViewModel,
                          title: S.of(context).popular_assets,
                          tokens: visiblePopular,
                          onSeeAll: sections.popular.length > visiblePopular.length
                              ? () => _openSeeAll(
                                    S.of(context).popular_assets,
                                    () => _homeSettingsViewModel.tokenSections.popular,
                                  )
                              : null,
                        ),
                      if (sections.other.isNotEmpty)
                        TokenListSection(
                          viewModel: _homeSettingsViewModel,
                          title: S.of(context).other_assets,
                          tokens: visibleOther,
                          onSeeAll: sections.other.length > visibleOther.length
                              ? () => _openSeeAll(
                                    S.of(context).other_assets,
                                    () => _homeSettingsViewModel.tokenSections.other,
                                  )
                              : null,
                        ),
                    ],
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
