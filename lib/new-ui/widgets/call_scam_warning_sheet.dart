import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:cake_wallet/wallet_type_utils.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

class CallScamWarningSheet extends StatelessWidget {
  const CallScamWarningSheet({super.key});

  static const _supportEmail = "support@cakewallet.com";
  static const _supportTelegram = "cakewallet_bot";

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const CallScamWarningSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final warningColor = context.customColors.warningOutlineColor;
    final strings = S.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
              leadingSemanticLabel: strings.close,
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
                                colorFilter: ColorFilter.mode(warningColor, BlendMode.srcIn),
                              ),
                              Text(
                                strings.call_scam_sheet_title,
                                textAlign: TextAlign.center,
                                style: textTheme.titleMedium,
                              ),
                            ],
                          ),
                          Text(
                            "${strings.call_scam_sheet_never_call(approximatedAppName)}\n\n"
                            "${strings.call_scam_sheet_urgency}",
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Card(
                      child: Text(
                        strings.call_scam_sheet_contact_support,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(color: warningColor),
                      ),
                    ),
                    NewListSections(
                      sections: {
                        "": [
                          ListItemRegularRow(
                            keyValue: "call_scam_sheet_email",
                            label: strings.email,
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
                            label: strings.live_chat,
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
              child: NewPrimaryButton(
                onPressed: Navigator.of(context).pop,
                text: strings.i_understand,
                color: colorScheme.primary,
                textColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
