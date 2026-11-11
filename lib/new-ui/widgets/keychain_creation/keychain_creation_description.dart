import "dart:io";

import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:flutter/material.dart";
import "package:smooth_page_indicator/smooth_page_indicator.dart";

class KeychainCreationDescriptionModal extends StatefulWidget {
  const KeychainCreationDescriptionModal({super.key});

  @override
  State<KeychainCreationDescriptionModal> createState() => _KeychainCreationDescriptionModalState();
}

class _KeychainCreationDescriptionModalState extends State<KeychainCreationDescriptionModal> {
  static const _pages = [
    _RecoveryPhrasePage(),
    _RecoveryPhraseRisksPage(),
    _CloudKeysPage(),
    _CloudKeysRequirementsPage(),
    _SummaryPage(),
  ];

  late PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                ModalTopBar(
                  title: S.of(context).recovery_phrase_backup,
                  trailingIcon: const Icon(Icons.close),
                  trailingSemanticLabel: S.of(context).close,
                  onTrailingPressed: Navigator.of(context).pop,
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: _pages,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    spacing: 24,
                    children: [
                      SmoothPageIndicator(
                        controller: _controller,
                        count: _pages.length,
                        effect: ColorTransitionEffect(
                          spacing: 8,
                          radius: 4.8,
                          dotWidth: 9.6,
                          dotHeight: 9.6,
                          dotColor: Theme.of(context).colorScheme.onSurfaceVariant,
                          activeDotColor: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      NewPrimaryButton(
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            );
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        text: S.of(context).continue_text,
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ExplainerPage extends StatelessWidget {
  const _ExplainerPage({required this.children, this.spacing = 36});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 17),
          child: Column(mainAxisSize: MainAxisSize.min, spacing: spacing, children: children),
        ),
      );
}

class _ExplainerText extends StatelessWidget {
  const _ExplainerText(this.spans, {this.color, this.padded = true});

  final List<InlineSpan> spans;
  final Color? color;
  final bool padded;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: padded ? 12 : 0),
        child: Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: color ?? Theme.of(context).colorScheme.onSurface,
              ),
        ),
      );
}

class _CloudKeysImage extends StatelessWidget {
  const _CloudKeysImage({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => CakeImageWidget(
        imageUrl: "assets/new-ui/cloud_keys.svg",
        width: width,
        height: width * 0.7273,
        fit: BoxFit.cover,
      );
}

TextSpan _highlight(BuildContext context, String text) =>
    TextSpan(text: text, style: TextStyle(color: Theme.of(context).colorScheme.primary));

class _RecoveryPhrasePage extends StatelessWidget {
  const _RecoveryPhrasePage();

  @override
  Widget build(BuildContext context) => _ExplainerPage(
        children: [
          Column(
            spacing: 12,
            children: [
              _ExplainerText([
                TextSpan(text: "${S.of(context).explainer_recovery_phrase_only_info} "),
                _highlight(context, S.of(context).seed_title),
              ]),
              _ExplainerText(
                [TextSpan(text: S.of(context).explainer_word_list)],
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const CakeImageWidget(
            imageUrl: "assets/new-ui/recovery_phrase_card.svg",
            width: 229,
            height: 137,
          ),
          _ExplainerText([TextSpan(text: S.of(context).explainer_primary_recovery_method)]),
        ],
      );
}

class _RecoveryPhraseRisksPage extends StatelessWidget {
  const _RecoveryPhraseRisksPage();

  @override
  Widget build(BuildContext context) {
    final warningColor = context.currentTheme.customColors.warningOutlineColor;

    return _ExplainerPage(
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 32,
          children: [
            CakeImageWidget(
              imageUrl: "assets/new-ui/warning_triangle.svg",
              width: 100,
              height: 100,
            ),
            CakeImageWidget(
              imageUrl: "assets/new-ui/recovery_phrase_paper.svg",
              width: 102,
              height: 100,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            spacing: 24,
            children: [
              _ExplainerText(
                [TextSpan(text: S.of(context).explainer_responsibility_risks)],
                padded: false,
              ),
              Column(
                spacing: 12,
                children: [
                  _RiskBullet(text: S.of(context).explainer_risk_lost, color: warningColor),
                  _RiskBullet(text: S.of(context).explainer_risk_leaked, color: warningColor),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RiskBullet extends StatelessWidget {
  const _RiskBullet({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14, color: color);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 21, child: Text("•", textAlign: TextAlign.center, style: style)),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

class _CloudKeysPage extends StatelessWidget {
  const _CloudKeysPage();

  @override
  Widget build(BuildContext context) {
    final cloudServiceName = Platform.isAndroid ? S.of(context).google_drive : "iCloud Keychain";

    return _ExplainerPage(
      children: [
        Column(
          spacing: 24,
          children: [
            const _CloudKeysImage(width: 100),
            _ExplainerText(
              [
                TextSpan(text: "${S.of(context).explainer_cloud_keys_prefix} "),
                _highlight(context, S.of(context).cloud_keys),
                TextSpan(text: " ${S.of(context).explainer_cloud_keys_suffix}"),
              ],
              padded: false,
            ),
          ],
        ),
        Column(
          spacing: 24,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                if (Platform.isIOS)
                  const CakeImageWidget(
                    imageUrl: "assets/images/icloud_logo.png",
                    width: 75,
                    height: 75,
                  ),
                const CakeImageWidget(
                    imageUrl: "assets/new-ui/key_blue.svg", width: 75, height: 75),
              ],
            ),
            _ExplainerText([
              TextSpan(text: "${S.of(context).explainer_cloud_service_prefix(cloudServiceName)} "),
              _highlight(context, S.of(context).seed_title),
              TextSpan(text: " ${S.of(context).explainer_cloud_service_suffix}"),
            ]),
          ],
        ),
      ],
    );
  }
}

class _CloudKeysRequirementsPage extends StatelessWidget {
  const _CloudKeysRequirementsPage();

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
    const checkmark = CakeImageWidget(
      imageUrl: "assets/new-ui/checkmark_green.svg",
      width: 24,
      height: 24,
    );

    return _ExplainerPage(
      spacing: 40,
      children: [
        const _CloudKeysImage(width: 100),
        Column(
          spacing: 24,
          children: [
            Column(
              spacing: 12,
              children: [
                _ExplainerText([TextSpan(text: S.of(context).explainer_access_needed)]),
                NewListSections(
                  sections: {
                    "": [
                      ListItemRegularRow(
                        keyValue: "account",
                        label: Platform.isAndroid
                            ? S.of(context).your_google_account
                            : S.of(context).your_apple_account,
                        iconPath: Platform.isIOS ? "assets/new-ui/apple_logo.svg" : null,
                        iconColor: iconColor,
                        showArrow: false,
                        trailingWidget: checkmark,
                      ),
                      ListItemRegularRow(
                        keyValue: "app",
                        label: S.of(context).cake_wallet_app,
                        iconPath: "assets/new-ui/cake_wallet_app.svg",
                        iconColor: iconColor,
                        showArrow: false,
                        trailingWidget: checkmark,
                      ),
                    ],
                  },
                ),
              ],
            ),
            _ExplainerText(
              [TextSpan(text: S.of(context).explainer_perform_manual_backup)],
              color: context.currentTheme.customColors.warningOutlineColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryPage extends StatelessWidget {
  const _SummaryPage();

  @override
  Widget build(BuildContext context) => _ExplainerPage(
        spacing: 24,
        children: [
          _ExplainerText(
            [TextSpan(text: S.of(context).in_summary)],
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          Column(
            spacing: 12,
            children: [
              _SummaryCard(
                icon: const CakeImageWidget(
                  imageUrl: "assets/new-ui/manual_backup.svg",
                  width: 48,
                  height: 48,
                ),
                title: S.of(context).manual_backup,
                badge: S.of(context).most_compatible,
                description: S.of(context).explainer_manual_backup_desc,
              ),
              _SummaryCard(
                icon: const _CloudKeysImage(width: 48),
                title: S.of(context).cloud_keychain,
                badge: S.of(context).most_convenient,
                description: S.of(context).explainer_cloud_keychain_desc,
              ),
            ],
          ),
          _ExplainerText([TextSpan(text: S.of(context).explainer_both_actions_in_settings)]),
        ],
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.badge,
    required this.description,
  });

  static const badgeColor = Color(0xFF5FFF8A);

  final Widget icon;
  final String title;
  final String badge;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          spacing: 24,
          children: [
            icon,
            Column(
              spacing: 12,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: "$title: "),
                      TextSpan(text: badge, style: const TextStyle(color: badgeColor)),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      );
}
