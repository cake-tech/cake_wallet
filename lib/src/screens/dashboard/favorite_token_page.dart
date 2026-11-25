import "dart:async";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/screens/dashboard/widgets/token_list_section.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/view_model/dashboard/home_settings_view_model.dart";
import "package:flutter/material.dart";

class FavoriteTokenPage extends BasePage {
  FavoriteTokenPage(this._homeSettingsViewModel);

  final HomeSettingsViewModel _homeSettingsViewModel;

  @override
  String? get title => S.current.favorite_token;

  @override
  Widget body(BuildContext context) {
    final tokens = _homeSettingsViewModel.enabledTokens;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 24,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              S.of(context).favorite_token_desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: -0.06,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Column(
            children: [
              for (final (index, token) in tokens.indexed)
                TokenRow(
                  viewModel: _homeSettingsViewModel,
                  token: token,
                  iconSize: 24,
                  showBalance: false,
                  isFirstInSection: index == 0,
                  isLastInSection: index == tokens.length - 1,
                  onTap: () {
                    unawaited(_homeSettingsViewModel.setFavoriteToken(token));
                    Navigator.of(context).pop();
                  },
                  trailing: CakeImageWidget(
                    imageUrl: "assets/new-ui/arrow_forward.svg",
                    height: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
