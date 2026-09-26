import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/modal_header.dart";
import "package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/base_alert_dialog.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/reset_view_model.dart";
import "package:flutter/material.dart";

class ResetPage extends StatelessWidget {
  const ResetPage(this._resetViewModel, {super.key});

  final ResetViewModel _resetViewModel;

  @override
  Widget build(BuildContext context) => ModalPageWrapper(
        topBar: ModalTopBar(
          title: "",
          leadingIcon: const Icon(Icons.arrow_back_ios_new),
          leadingSemanticLabel: S.of(context).seed_alert_back,
          onLeadingPressed: () => Navigator.of(context).pop(),
        ),
        header: ModalHeader(
          iconPath: "assets/new-ui/settings_row_icons/reset.svg",
          title: S.of(context).reset,
          message: S.of(context).reset_desc,
        ),
        content: NewListSections(
          sections: {
            if (_resetViewModel.hasRescan)
              "rescan": [
                ListItemRegularRow(
                  keyValue: "rescan_current_wallet",
                  label: S.of(context).rescan_current_wallet,
                  onTap: () => Navigator.of(context).pushNamed(Routes.rescan),
                ),
              ],
            "reset_actions": [
              ListItemRegularRow(
                keyValue: "reset_balance_cards",
                label: S.of(context).reset_balance_cards,
                foregroundColor: Theme.of(context).colorScheme.primary,
                showArrow: false,
                onTap: () => _resetBalanceCards(context),
              ),
              ListItemRegularRow(
                keyValue: "reset_settings_to_default",
                label: S.of(context).reset_settings_to_default,
                foregroundColor: Theme.of(context).colorScheme.primary,
                showArrow: false,
                onTap: () => _resetSettingsToDefault(context),
              ),
            ],
          },
        ),
      );

  Future<void> _resetBalanceCards(BuildContext context) async {
    final shouldReset = await showPopUp<bool>(
      context: context,
      builder: (dialogContext) => AlertWithTwoActions(
        alertTitle: S.of(dialogContext).alert_notice,
        alertContent: S.of(dialogContext).reset_balance_cards_notice,
        rightButtonText: S.of(dialogContext).continue_text,
        leftButtonText: S.of(dialogContext).cancel,
        leftAlertButtonStyle: AlertButtonStyle.primary(dialogContext),
        rightAlertButtonStyle: AlertButtonStyle.secondary(dialogContext),
        actionRightButton: () => Navigator.of(dialogContext).pop(true),
        actionLeftButton: () => Navigator.of(dialogContext).pop(false),
      ),
    );

    if (shouldReset == true) {
      await _resetViewModel.resetBalanceCards();
    }
  }

  Future<void> _resetSettingsToDefault(BuildContext context) async {
    final shouldReset = await showPopUp<bool>(
      context: context,
      builder: (dialogContext) => AlertWithTwoActions(
        alertTitle: S.of(dialogContext).alert_notice,
        alertContent: S.of(dialogContext).reset_wallet_settings_notice,
        rightButtonText: S.of(dialogContext).continue_text,
        leftButtonText: S.of(dialogContext).cancel,
        leftAlertButtonStyle: AlertButtonStyle.primary(dialogContext),
        rightAlertButtonStyle: AlertButtonStyle.secondary(dialogContext),
        actionRightButton: () => Navigator.of(dialogContext).pop(true),
        actionLeftButton: () => Navigator.of(dialogContext).pop(false),
      ),
    );

    if (shouldReset == true) {
      await _resetViewModel.resetSettingsToDefault();
    }
  }
}
