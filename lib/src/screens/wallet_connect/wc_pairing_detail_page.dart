import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/wc_permissions_mapper.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_dapp_card.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_permissions_card.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_wallet_card.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class WalletConnectPairingDetailsPage extends StatefulWidget {
  final PairingInfo pairing;
  final WalletKitService walletKitService;

  const WalletConnectPairingDetailsPage({
    required this.pairing,
    required this.walletKitService,
    super.key,
  });

  @override
  WalletConnectPairingDetailsPageState createState() => WalletConnectPairingDetailsPageState();
}

class WalletConnectPairingDetailsPageState extends State<WalletConnectPairingDetailsPage> {
  late String expiryDate;
  List<SessionData> sessions = const [];

  @override
  void initState() {
    super.initState();
    initDateTime();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        sessions = widget.walletKitService.getSessionsForPairingInfo(widget.pairing);
      });
    });
  }

  void initDateTime() {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(widget.pairing.expiry * 1000);
    expiryDate = '${dateTime.year}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return WCCDetailsWidget(
      pairing: widget.pairing,
      expiryDate: expiryDate,
      sessions: sessions,
      walletKitService: widget.walletKitService,
    );
  }
}

class WCCDetailsWidget extends BasePage {
  WCCDetailsWidget({
    required this.pairing,
    required this.expiryDate,
    required this.sessions,
    required this.walletKitService,
  });

  final PairingInfo pairing;
  final String expiryDate;
  final List<SessionData> sessions;
  final WalletKitService walletKitService;

  @override
  Widget body(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final metadata = pairing.peerMetadata;
    if (metadata == null) {
      return const SizedBox.shrink();
    }

    final iconUrl = metadata.icons.isNotEmpty ? metadata.icons.first : null;
    final walletName = getIt.get<AppStore>().wallet?.name ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WCDappCard(
              name: metadata.name,
              iconUrl: iconUrl,
              subtitle: metadata.url,
              action: WCDappCardAction.connected,
            ),
            const SizedBox(height: 12),
            Text(
              '${S.of(context).expiresOn}: $expiryDate',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            for (final session in sessions) ...[
              _SessionSection(
                session: session,
                walletName: walletName,
              ),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 24),
            NewPrimaryButton(
              onPressed: () => _onDeleteButtonPressed(context, metadata.name, walletKitService),
              text: S.current.delete,
              color: colors.error,
              textColor: colors.onError,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _onDeleteButtonPressed(
    BuildContext context,
    String dAppName,
    WalletKitService walletKitService,
  ) async {
    bool confirmed = false;

    await showPopUp<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertWithTwoActions(
          alertTitle: S.of(context).delete,
          alertContent: '${S.current.deleteConnectionConfirmationPrompt} $dAppName?',
          leftButtonText: S.of(context).cancel,
          rightButtonText: S.of(context).delete,
          actionLeftButton: () => Navigator.of(dialogContext).pop(),
          actionRightButton: () {
            confirmed = true;
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
    if (confirmed) {
      try {
        await walletKitService.deletePairing(topic: pairing.topic);

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }
}

class _SessionSection extends StatelessWidget {
  const _SessionSection({
    required this.session,
    required this.walletName,
  });

  final SessionData session;
  final String walletName;

  String _firstAddress() {
    for (final namespace in session.namespaces.values) {
      if (namespace.accounts.isNotEmpty) {
        return NamespaceUtils.getAccount(namespace.accounts.first);
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final permissions = WCPermissionsMapper.fromGeneratedNamespaces(session.namespaces);
    final address = _firstAddress();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WCWalletCard(walletName: walletName, address: address),
        const SizedBox(height: 24),
        WCPermissionsCard(permissions: permissions),
      ],
    );
  }
}
