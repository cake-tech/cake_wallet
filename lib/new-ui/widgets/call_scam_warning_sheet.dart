import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/base_alert_dialog.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/wallet_type_utils.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

class CallScamWarningSheet extends StatelessWidget {
  const CallScamWarningSheet({required this.onDontShowAgain, super.key});

  final VoidCallback onDontShowAgain;

  static const _supportEmail = "support@cakewallet.com";
  static const _supportTelegram = "cakewallet_bot";

  static Future<void> show(BuildContext context, {required VoidCallback onDontShowAgain}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CallScamWarningSheet(onDontShowAgain: onDontShowAgain),
      );

  Future<void> _confirmDontShowAgain(BuildContext context) async {
    final confirmed = await showPopUp<bool>(
      context: context,
      builder: (dialogContext) => AlertWithTwoActions(
        alertTitle: S.of(dialogContext).are_you_sure,
        alertContent: "",
        alertContentTextWidget: Text(
          S.of(dialogContext).call_scam_warning_disable_confirmation,
          textAlign: TextAlign.center,
          style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
              ),
        ),
        leftButtonText: S.of(dialogContext).yes,
        rightButtonText: S.of(dialogContext).cancel,
        leftAlertButtonStyle: AlertButtonStyle.secondary(dialogContext),
        rightAlertButtonStyle: AlertButtonStyle(
          backgroundColor: Theme.of(dialogContext).colorScheme.primary,
          textColor: Theme.of(dialogContext).colorScheme.onPrimary,
          fontWeight: FontWeight.w500,
        ),
        actionLeftButton: () => Navigator.of(dialogContext).pop(true),
        actionRightButton: () => Navigator.of(dialogContext).pop(false),
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop();
      onDontShowAgain();
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          minimum: const EdgeInsets.only(bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalTopBar(
                title: "",
                leadingIcon: const Icon(Icons.close),
                leadingSemanticLabel: S.of(context).close,
                onLeadingPressed: Navigator.of(context).pop,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    spacing: 24,
                    children: [
                      _Card(
                        child: Column(
                          spacing: 24,
                          children: [
                            Column(
                              spacing: 10,
                              children: [
                                CakeImageWidget(
                                  imageUrl: "assets/new-ui/warning_filled.svg",
                                  width: 48,
                                  height: 48,
                                  colorFilter: ColorFilter.mode(
                                    context.customColors.warningOutlineColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                Text(
                                  S.of(context).call_scam_sheet_title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            Text(
                              "${S.of(context).call_scam_sheet_never_call(approximatedAppName)}\n\n"
                              "${S.of(context).call_scam_sheet_urgency}",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _Card(
                        child: Text(
                          S.of(context).call_scam_sheet_contact_support,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: context.customColors.warningOutlineColor),
                        ),
                      ),
                      NewListSections(
                        sections: {
                          "": [
                            ListItemRegularRow(
                              keyValue: "call_scam_sheet_email",
                              label: S.of(context).email,
                              trailingText: _supportEmail,
                              showArrow: false,
                              onTap: () => launchUrl(
                                Uri(scheme: "mailto", path: _supportEmail),
                                mode: LaunchMode.externalApplication,
                              ),
                            ),
                            ListItemRegularRow(
                              keyValue: "call_scam_sheet_telegram",
                              label: "Telegram",
                              trailingText: _supportTelegram,
                              showArrow: false,
                              onTap: () => launchUrl(
                                Uri.https("t.me", _supportTelegram),
                                mode: LaunchMode.externalApplication,
                              ),
                            ),
                            ListItemRegularRow(
                              keyValue: "call_scam_sheet_live_chat",
                              label: S.of(context).live_chat,
                              onTap: () => Navigator.of(context, rootNavigator: true)
                                  .pushNamed(Routes.supportLiveChat),
                            ),
                          ],
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                child: Column(
                  spacing: 12,
                  children: [
                    NewPrimaryButton(
                      onPressed: () => _confirmDontShowAgain(context),
                      text: S.of(context).dont_show_again,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      textColor: Theme.of(context).colorScheme.primary,
                    ),
                    NewPrimaryButton(
                      onPressed: Navigator.of(context).pop,
                      text: S.of(context).i_understand,
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      );
}
