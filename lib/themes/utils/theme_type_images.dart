import 'package:cake_wallet/themes/core/material_base_theme.dart';

extension ThemeTypeImages on ThemeType {
  String get walletGroupImage {
    switch (this) {
      case ThemeType.light:
        return 'assets/images/wallet_group_light.png';
      case ThemeType.dark:
        return 'assets/images/wallet_group_dark.png';
    }
  }
}
