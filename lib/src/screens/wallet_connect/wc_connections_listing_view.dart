import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/walletkit_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/enter_wallet_connect_uri_widget.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/wc_hero_card.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/permission_handler.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

import 'wc_pairing_detail_page.dart';

class WalletConnectConnectionsView extends StatelessWidget {
  WalletConnectConnectionsView({
    required this.walletKitService,
    Uri? launchUri,
    Key? key,
  }) : super(key: key) {
    _triggerPairingFromDeeplink(launchUri);
  }

  final WalletKitService walletKitService;

  void _triggerPairingFromDeeplink(Uri? launchUri) async {
    if (launchUri == null) return;

    if (launchUri.scheme == 'wc') {
      await walletKitService.pairWithUri(launchUri);
      return;
    }

    final actualLinkList = launchUri.query.split('uri=');
    if (actualLinkList.length <= 1) return;

    final decoded = Uri.decodeComponent(actualLinkList[1]).trim();
    final sanitized = decoded.startsWith('@') ? decoded.substring(1) : decoded;
    final uriData = Uri.tryParse(sanitized);
    if (uriData == null || uriData.scheme.isEmpty) return;

    await walletKitService.pairWithUri(uriData);
  }

  Future<void> _onScanQrCode(BuildContext context) async {
    final isCameraPermissionGranted =
        await PermissionHandler.checkPermission(Permission.camera, context);
    if (!isCameraPermissionGranted) return;

    final uri = await presentQRScanner(context);
    await _handleWalletConnectURI(uri, context);
  }

  Future<void> _onPasteLink(BuildContext context) async {
    final uri = await showPopUp<String>(
      context: context,
      builder: (BuildContext context) => EnterWalletConnectURIWrapperWidget(),
    );
    await _handleWalletConnectURI(uri, context);
  }

  Future<void> _handleWalletConnectURI(String? walletConnectURI, BuildContext context) async {
    if (walletConnectURI == null) return _invalidUriToast(context, S.current.nullURIError);

    String input = walletConnectURI.trim();
    if (input.contains('uri=')) {
      final parts = input.split('uri=');
      if (parts.length > 1) input = Uri.decodeComponent(parts.last);
    }
    if (input.startsWith('@')) input = input.substring(1);

    final uriData = Uri.tryParse(input);
    if (uriData == null || uriData.scheme.isEmpty) {
      return _invalidUriToast(context, S.current.invalid_input);
    }

    await walletKitService.pairWithUri(uriData);
  }

  Future<void> _invalidUriToast(BuildContext context, String message) async {
    await showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertWithOneAction(
          alertTitle: S.of(context).error,
          alertContent: message,
          buttonText: S.of(context).ok,
          buttonAction: Navigator.of(context).pop,
          alertBarrierDismissible: false,
        );
      },
    );
  }

  void _openPairingDetails(BuildContext context, PairingInfo pairing) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WalletConnectPairingDetailsPage(
          pairing: pairing,
          walletKitService: walletKitService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isMobile = DeviceInfo.instance.isMobile;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ModernButton(
                  size: 40,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(Icons.arrow_back_ios_new, size: 16),
                  semanticLabel: S.of(context).seed_alert_back,
                  iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const WCHeroCard(),
                      const SizedBox(height: 24),
                      Observer(
                        builder: (_) {
                          if (walletKitService.pairings.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  S.of(context).activeConnectionsPrompt,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          }

                          final items = <ListItemRegularRow>[];
                          for (final pairing in walletKitService.pairings) {
                            final metadata = pairing.peerMetadata;
                            if (metadata == null) continue;
                            items.add(
                              ListItemRegularRow(
                                keyValue: pairing.topic,
                                label: metadata.name,
                                subtitle: metadata.url,
                                iconPath: metadata.icons.isNotEmpty
                                    ? metadata.icons.first
                                    : 'assets/new-ui/walletconnect_icon.svg',
                                onTap: () => _openPairingDetails(context, pairing),
                                leadingIconSize: 36,
                                leadingIconErrorWidget: CakeImageWidget(
                                  imageUrl: 'assets/new-ui/walletconnect_icon.svg',
                                  width: 36,
                                  height: 36,
                                ),
                              ),
                            );
                          }

                          if (items.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  S.of(context).activeConnectionsPrompt,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          }

                          return NewListSections(sections: {'': items});
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              NewPrimaryButton(
                onPressed: () => _onPasteLink(context),
                text: S.of(context).wc_paste_link,
                color: colors.surfaceContainerHigh,
                textColor: colors.primary,
              ),
              if (isMobile) ...[
                const SizedBox(height: 12),
                NewPrimaryButton(
                  onPressed: () => _onScanQrCode(context),
                  text: S.of(context).wc_scan_qr,
                  color: colors.primary,
                  textColor: colors.onPrimary,
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
