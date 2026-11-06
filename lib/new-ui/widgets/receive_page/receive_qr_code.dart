import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../src/screens/receive/widgets/qr_image.dart';

class ReceiveQrCode extends StatelessWidget {
  ReceiveQrCode({
    super.key,
    required this.onTap,
    required this.largeQrMode,
    required this.addressListViewModel,
  });

  final VoidCallback onTap;
  final bool largeQrMode;
  final WalletAddressListViewModel addressListViewModel;

  static const double largeQrModeBottomPadding = 140;
  static const Duration animDuration = Duration(milliseconds: 500);
  final bool isLightMode = !(getIt.get<ThemeStore>().currentTheme.isDark);

  /// Placeholder filler for the QR shown while the payjoin receiver is being
  /// initialized, sized to visually match the module density of a real BIP21
  /// payjoin URI. The pj host uses the RFC 2606 reserved `.invalid` TLD, so
  /// it can never resolve to a live directory; the address part is the
  /// wallet's real address, so even in the pathological case of a scanner
  /// decoding through the blur, a payjoin POST can only fail loudly — funds
  /// could never be redirected.
  static const String _placeholderPjParams =
      "?amount=0.00001&pj=https://payjoin.invalid/8f3kq2xvm9tzw5r1yh7bnc4dgs6jpeaulo4i5teb2w9rk3cyq6vh1d7nzmxg0sapf8ujt2lcwe5oy9b3irdg4kn7qvz6h1m5txe0f9r2wak7cy&pjos=0";

  @override
  Widget build(BuildContext context) {
    final double targetY = largeQrMode ? largeQrModeBottomPadding + 50 : 0;
    final double resolvedSize =
        min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height) * 0.5;
    final double resolvedScale = largeQrMode ? 1.7 : 1;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AnimatedSlide(
          curve: Curves.easeOutCubic,
          duration: animDuration,
          offset: largeQrMode ? Offset(0, -1) : Offset.zero,
          child: AnimatedOpacity(
              duration: animDuration,
              opacity: largeQrMode ? 1 : 0,
              child: CakeImageWidget(
                imageUrl: isLightMode
                    ? "assets/new-ui/cakewallet-wordmark-light.svg"
                    : "assets/new-ui/cakewallet-wordmark.svg",
                height: 45,
              )),
        ),
        // The QR, and the payjoin badge below it, share one tap target, so they
        // are merged into a single button node named by the QR's own label
        // rather than each becoming a separate focus stop.
        MergeSemantics(
          child: Semantics(
            hint: largeQrMode ? S.of(context).qr_close_fullscreen : S.of(context).qr_fullscreen,
            button: true,
            enabled: true,
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: targetY),
                duration: animDuration,
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, value),
                    child: child,
                  );
                },
                child: Observer(
                  builder: (_) => Column(
                    children: [
                      AnimatedScale(
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.bottomCenter,
                        scale: resolvedScale,
                        duration: animDuration,
                        child: AnimatedContainer(
                          duration: animDuration,
                          curve: Curves.easeOutCubic,
                          width: resolvedSize,
                          height: resolvedSize,
                          decoration: BoxDecoration(
                            // Square bottom corners whenever the badge is
                            // mounted below, so tile + badge read as one
                            // continuous block in both QR modes; the bottom
                            // rounding only exists for the standalone tile.
                            borderRadius:
                                (addressListViewModel.hasPayjoin ||
                                        addressListViewModel.isPayjoinLoading)
                                    ? const BorderRadius.vertical(
                                        top: Radius.circular(20))
                                    : BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                color: (addressListViewModel.hasPayjoin ||
                                        addressListViewModel.isPayjoinLoading) &&
                                        !largeQrMode
                                    ? Theme.of(context).colorScheme.surfaceContainer
                                    : Colors.transparent),
                            child: ClipRRect(
                                borderRadius: (addressListViewModel.hasPayjoin ||
                                        addressListViewModel.isPayjoinLoading)
                                    ? const BorderRadius.vertical(
                                        top: Radius.circular(20))
                                    : BorderRadius.circular(20),
                                child: Observer(builder: (_) {
                                  final isPjPending =
                                      addressListViewModel.isPayjoinLoading;
                                  final embeddedImagePath =
                                      addressListViewModel.tokenCurrency != null
                                          ? addressListViewModel.tokenCurrency ==
                                                  CryptoCurrency.btcln
                                              ? addressListViewModel.qrImage
                                              : addressListViewModel
                                                  .tokenCurrency!.iconPath
                                          : addressListViewModel.qrImage;
                                  if (!isPjPending) {
                                    return QrImage(
                                      data: addressListViewModel.uri.toString(),
                                      size: resolvedSize,
                                      semanticsLabel:
                                          S.of(context).qr_code_receive_address,
                                      embeddedImagePath: embeddedImagePath,
                                    );
                                  }
                                  // The payjoin receiver is still negotiating
                                  // with the directory over the OHTTP relay.
                                  // Show a blurred, unscannable stand-in
                                  // shaped like a real pjuri instead of
                                  // flashing the plain-address QR first; when
                                  // initialization fails, this is replaced by
                                  // the standard address QR.
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ImageFiltered(
                                        imageFilter: ImageFilter.blur(
                                            sigmaX: 8, sigmaY: 8),
                                        child: QrImage(
                                          data:
                                              "bitcoin:${addressListViewModel.uri.address}$_placeholderPjParams",
                                          size: resolvedSize,
                                          semanticsLabel: S.of(context).loading,
                                          embeddedImagePath: embeddedImagePath,
                                        ),
                                      ),
                                      const ExcludeSemantics(
                                          child: CupertinoActivityIndicator()),
                                    ],
                                  );
                                })),
                          ),
                        ),
                      ),
                      // Kept mounted (collapsed to zero height when payjoin is
                      // neither active nor initializing) so the badge grows
                      // and shrinks smoothly instead of popping in and out.
                      ClipRect(
                        child: AnimatedAlign(
                          duration: animDuration,
                          curve: Curves.easeOutCubic,
                          heightFactor:
                              addressListViewModel.hasPayjoin ||
                                      addressListViewModel.isPayjoinLoading
                                  ? 1
                                  : 0,
                          alignment: Alignment.center,
                          // Width tracks the QR's visual width in both modes
                          // (the QR itself grows via AnimatedScale), so the
                          // badge always spans the QR's edges while its text
                          // height stays unchanged. Same duration/curve as
                          // the QR's scale → grows in lockstep.
                          child: ExcludeSemantics(
                            // The badge only becomes meaningful once payjoin is
                            // actually active; while the placeholder QR is up
                            // it is merely provisional, so keep it out of the
                            // semantics tree until then.
                            excluding: !addressListViewModel.hasPayjoin,
                            child: AnimatedContainer(
                              duration: animDuration,
                              curve: Curves.easeOutCubic,
                              width: resolvedSize * resolvedScale,
                              decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.vertical(bottom: Radius.circular(16)),
                                  color: Theme.of(context).colorScheme.surfaceContainer),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 4,
                                  children: [
                                    CakeImageWidget(imageUrl: "assets/new-ui/payjoin.svg"),
                                    Text(S.of(context).payjoin_enabled)
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      AnimatedSize(
                          duration: animDuration,
                          curve: Curves.easeOutCubic,
                          child: SizedBox(height: largeQrMode ? largeQrModeBottomPadding + 40 : 0))
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
