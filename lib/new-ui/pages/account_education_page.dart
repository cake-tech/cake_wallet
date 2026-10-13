import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/education_page.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class AccountEducationPage extends EducationPage {
  const AccountEducationPage({required super.settingsStore, super.key});

  @override
  String get educationId => "accounts";

  @override
  String get title => S.current.accounts;

  @override
  String get iconPath => "assets/new-ui/settings_row_icons/accounts.svg";

  @override
  String get completionLabel => S.current.accounts_education_understand_continue;

  @override
  String progressLabel(int current, int total) =>
      S.current.accounts_education_progress("$current", "$total");

  @override
  List<EducationSlide> get slides => <EducationSlide>[
        EducationSlide(
          distributeChildren: true,
          children: [
            EducationText(text: S.current.accounts_education_organize_title),
            const CakeImageWidget(
              imageUrl: "assets/new-ui/account_education/accounts_overview.svg",
              key: ValueKey("accounts-education-overview-image"),
              width: 133,
              height: 324,
              fit: BoxFit.contain,
            ),
            EducationText(
              text: S.current.accounts_education_organize_description,
              secondary: true,
            ),
          ],
        ),
        EducationSlide(
          children: [
            const CakeImageWidget(
              imageUrl: "assets/new-ui/account_education/recovery_shield.svg",
              key: ValueKey("accounts-education-recovery-image"),
              width: 213,
              height: 213,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 25.5),
            EducationText(
              text: S.current.accounts_education_recovery_title,
              highlightedText: S.current.accounts_education_recovery_highlight,
            ),
            const SizedBox(height: 25.5),
            EducationText(
              text: S.current.accounts_education_recovery_description,
              secondary: true,
            ),
          ],
        ),
        EducationSlide(
          children: [
            const CakeImageWidget(
              imageUrl: "assets/new-ui/account_education/account_order.svg",
              key: ValueKey("accounts-education-order-image"),
              width: 309,
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 51),
            EducationText(text: S.current.accounts_education_order_title),
            const SizedBox(height: 51),
            const CakeImageWidget(
              imageUrl: "assets/new-ui/account_education/ordered_account.svg",
              key: ValueKey("accounts-education-ordered-account-image"),
              width: 160,
              height: 99,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 51),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EducationText(
                  text: S.current.accounts_education_order_description,
                  highlightedText: S.current.accounts_education_order_highlight,
                ),
                const SizedBox(height: 25.5),
                EducationText(
                  text: S.current.accounts_education_order_restore_description,
                  secondary: true,
                ),
              ],
            ),
          ],
        ),
        EducationSlide(
          children: [
            const CakeImageWidget(
              imageUrl: "assets/new-ui/account_education/archive_warning.svg",
              key: ValueKey("accounts-education-archive-image"),
              width: 232,
              height: 101,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 51),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EducationText(
                  text: S.current.accounts_education_archive_title,
                  warning: true,
                ),
                const SizedBox(height: 13),
                EducationText(
                  text: S.current.accounts_education_archive_description,
                  secondary: true,
                ),
              ],
            ),
          ],
        ),
      ];
}
