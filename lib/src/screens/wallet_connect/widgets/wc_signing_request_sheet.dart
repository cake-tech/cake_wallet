import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/confirm_swiper.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_dapp_card.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_message_card.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_scam_banner.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_sheet_header.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_wallet_card.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class WCSigningRequestSheet extends StatelessWidget {
  const WCSigningRequestSheet({
    super.key,
    required this.title,
    required this.swipeLabel,
    required this.dappName,
    required this.message,
    required this.walletName,
    required this.address,
    this.dappIconUrl,
    this.dappSubtitle,
    this.verifyContext,
    this.messageTitle,
    this.extraRows = const [],
    this.signAllCount,
  });

  final String title;
  final String swipeLabel;
  final String dappName;
  final String? dappIconUrl;
  final String? dappSubtitle;
  final String message;
  final String? messageTitle;
  final List<WCMessageRow> extraRows;
  final String walletName;
  final String address;
  final VerifyContext? verifyContext;
  final int? signAllCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final showSignAll = (signAllCount ?? 0) > 1;
    final isScam = verifyContext?.validation.scam ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WCSheetHeader(title: title),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                WCDappCard(
                  name: dappName,
                  iconUrl: dappIconUrl,
                  subtitle: dappSubtitle ?? '',
                  action: WCDappCardAction.sign,
                  verifyContext: verifyContext,
                ),
                if (isScam) ...[
                  const SizedBox(height: 16),
                  const WCScamBanner(),
                ],
                const SizedBox(height: 24),
                WCWalletCard(walletName: walletName, address: address),
                const SizedBox(height: 24),
                WCMessageCard(
                  title: messageTitle,
                  message: message,
                  extraRows: extraRows,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConfirmSwiper(
            swiperText: swipeLabel,
            accessibleNavigationModeButtonText: S.of(context).confirm,
            onConfirmed: () {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop(WCBottomSheetResult.one);
              }
            },
          ),
        ),
        if (showSignAll) ...[
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop(WCBottomSheetResult.all);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(S.of(context).wc_sign_all_count(signAllCount!.toString())),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
