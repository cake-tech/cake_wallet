import "package:cake_wallet/entities/wallet_contact.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/address_book/widgets/legacy_wallet_contacts_tab.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/utils/address_formatter.dart";
import "package:cake_wallet/utils/show_bar.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:qr_flutter/qr_flutter.dart";

class SimpleReceivePage extends StatelessWidget {
  const SimpleReceivePage({required this.contact, super.key});

  final WalletContact contact;

  static Future<void> show(BuildContext context, WalletContact contact) =>
      showMaterialModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withAlpha(80),
        builder: (_) => SimpleReceivePage(contact: contact),
      );

  Future<void> _copyAddress(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: contact.address));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconPath = walletContactIconPath(contact);
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.75;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Column(
          children: [
            ModalTopBar(
              title: S.of(context).receive,
              leadingIcon: const Icon(CupertinoIcons.back),
              leadingSemanticLabel: S.of(context).close,
              onLeadingPressed: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            // The QR takes the biggest share of the free height and stays square.
            Expanded(
              flex: 6,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _QrCard(address: contact.address, iconPath: iconPath),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            if (contact.addressKind != null)
              Text(
                contact.addressKind!.displayName(),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const Spacer(),
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: NewPrimaryButton(
                text: S.of(context).copy_address,
                color: theme.colorScheme.primary,
                textColor: theme.colorScheme.onPrimary,
                image: Icon(Icons.copy_rounded, size: 18, color: theme.colorScheme.onPrimary),
                onPressed: () => _copyAddress(context),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.address, required this.iconPath});

  final String address;
  final String? iconPath;

  static const _padding = 14.0;
  static const _logoRatio = 0.22;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: address,
        child: ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final qrSize = constraints.maxWidth - _padding * 2;
              final logoSize = qrSize * _logoRatio;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(_padding),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    QrImageView(
                      data: address,
                      size: qrSize,
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                    if (iconPath != null)
                      Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: CakeImageWidget(imageUrl: iconPath, fit: BoxFit.contain),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
}
