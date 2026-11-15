import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_search_field.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/screens/dashboard/widgets/token_list_section.dart";
import "package:cake_wallet/view_model/dashboard/home_settings_view_model.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

class TokenListPage extends BasePage {
  TokenListPage(this._homeSettingsViewModel, {required this.title, required this.tokens});

  final HomeSettingsViewModel _homeSettingsViewModel;

  @override
  final String title;

  final List<CryptoCurrency> Function() tokens;

  @override
  Widget body(BuildContext context) => _TokenListPageBody(_homeSettingsViewModel, tokens);
}

class _TokenListPageBody extends StatefulWidget {
  const _TokenListPageBody(this.viewModel, this.tokens);

  final HomeSettingsViewModel viewModel;
  final List<CryptoCurrency> Function() tokens;

  @override
  State<_TokenListPageBody> createState() => _TokenListPageBodyState();
}

class _TokenListPageBodyState extends State<_TokenListPageBody> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<TextEditingValue>(
        valueListenable: _searchController,
        builder: (_, search, __) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Observer(
                  builder: (_) => TokenListSection(
                    viewModel: widget.viewModel,
                    tokens: widget
                        .tokens()
                        .where((token) => widget.viewModel.matchesSearch(token, search.text))
                        .toList(),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 22),
              child: CurrencyPickerSearchField(
                controller: _searchController,
                hintText: S.of(context).search,
              ),
            ),
          ],
        ),
      );
}
