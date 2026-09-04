import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

class AccountsPromo extends StatefulWidget {
  const AccountsPromo({
    required this.preferences,
    required this.walletName,
    required this.onTap,
    super.key,
  });

  final SharedPreferences preferences;
  final String walletName;
  final VoidCallback onTap;

  @override
  State<AccountsPromo> createState() => _AccountsPromoState();
}

class _AccountsPromoState extends State<AccountsPromo> {
  late bool _dismissed;

  @override
  void initState() {
    super.initState();
    _dismissed = widget.preferences.getBool(PreferencesKey.accountsHomePromoDismissed) ?? false;
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    await widget.preferences.setBool(PreferencesKey.accountsHomePromoDismissed, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final strings = S.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Material(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CakeImageWidget(
                      imageUrl: "assets/new-ui/settings_row_icons/accounts.svg",
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(theme.colorScheme.primary, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            strings.accounts_home_promo_title(widget.walletName),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.accounts_home_promo_description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _dismiss,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  strings.do_not_show_anymore,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
