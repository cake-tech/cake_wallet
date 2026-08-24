import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/modal_header.dart";
import "package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:flutter/material.dart";

class ResetPage extends BasePage {
  @override
  bool get hideAppBar => true;

  @override
  Widget body(BuildContext context) {
    final strings = S.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ModalPageWrapper(
      topBar: ModalTopBar(
        title: "",
        leadingIcon: const Icon(Icons.arrow_back_ios_new),
        leadingSemanticLabel: strings.seed_alert_back,
        onLeadingPressed: () => Navigator.of(context).pop(),
      ),
      header: ModalHeader(
        iconPath: "assets/new-ui/settings_row_icons/reset.svg",
        title: strings.reset,
        message: strings.reset_desc,
      ),
      content: NewListSections(
        sections: {
          "rescan": [
            ListItemRegularRow(
              keyValue: "rescan_current_wallet",
              label: strings.rescan_current_wallet,
              onTap: _rescanCurrentWallet,
            ),
          ],
          "reset_actions": [
            ListItemRegularRow(
              keyValue: "restore_this_wallet",
              label: strings.restore_this_wallet,
              foregroundColor: primaryColor,
              showArrow: false,
              onTap: _restoreThisWallet,
            ),
            ListItemRegularRow(
              keyValue: "reset_balance_cards",
              label: strings.reset_balance_cards,
              foregroundColor: primaryColor,
              showArrow: false,
              onTap: _resetBalanceCards,
            ),
            ListItemRegularRow(
              keyValue: "reset_settings_to_default",
              label: strings.reset_settings_to_default,
              foregroundColor: primaryColor,
              showArrow: false,
              onTap: _resetSettingsToDefault,
            ),
          ],
        },
      ),
    );
  }

  void _rescanCurrentWallet() {}

  void _restoreThisWallet() {}

  void _resetBalanceCards() {}

  void _resetSettingsToDefault() {}
}
