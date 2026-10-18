import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/confirm_swiper.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/bottom_sheet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/key_service/wallet_connect_key_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/wc_permissions_mapper.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_dapp_card.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_permissions_card.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_scam_banner.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_sheet_header.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_wallet_card.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class WCConnectionRequestSheet extends StatelessWidget {
  const WCConnectionRequestSheet({
    super.key,
    required this.proposalData,
    required this.requester,
    required this.walletKeyService,
    required this.appStore,
    this.verifyContext,
  });

  final ProposalData proposalData;
  final ConnectionMetadata requester;
  final WalletConnectKeyService walletKeyService;
  final AppStore appStore;
  final VerifyContext? verifyContext;

  String _resolveAddress() {
    final wallet = appStore.wallet;
    if (wallet == null) return '';
    final keys = walletKeyService.getKeysForChain(wallet);
    if (keys.isEmpty) return '';
    return keys.first.publicKey;
  }

  @override
  Widget build(BuildContext context) {
    final permissions =
        WCPermissionsMapper.fromGeneratedNamespaces(proposalData.generatedNamespaces ?? const {});

    final metadata = requester.metadata;
    final iconUrl = metadata.icons.isNotEmpty ? metadata.icons.first : null;
    final walletName = appStore.wallet?.name ?? '';
    final address = _resolveAddress();
    final isScam = verifyContext?.validation.scam ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WCSheetHeader(title: S.of(context).wc_connect_request_title),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                WCDappCard(
                  name: metadata.name,
                  iconUrl: iconUrl,
                  subtitle: metadata.url,
                  action: WCDappCardAction.connect,
                  verifyContext: verifyContext,
                ),
                if (isScam) ...[
                  const SizedBox(height: 16),
                  const WCScamBanner(),
                ],
                const SizedBox(height: 24),
                WCWalletCard(walletName: walletName, address: address),
                const SizedBox(height: 24),
                WCPermissionsCard(permissions: permissions),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConfirmSwiper(
            swiperText: S.of(context).wc_swipe_to_approve,
            accessibleNavigationModeButtonText: S.of(context).wc_action_approve,
            onConfirmed: () {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop(WCBottomSheetResult.one);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
