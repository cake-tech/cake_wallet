import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/copy_wrapper.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_modal_header.dart";
import "package:cake_wallet/src/screens/receive/widgets/qr_image.dart";
import "package:cake_wallet/utils/address_formatter.dart";
import "package:cake_wallet/utils/clipboard_util.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/payment_uris.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class SwapSendExternalModal extends StatefulWidget {
  const SwapSendExternalModal(
      {required this.uri, required this.from, required this.to, super.key, this.extraId,});

  final CryptoCurrency from;
  final CryptoCurrency to;
  final PaymentURI uri;
  final String? extraId;

  @override
  State<SwapSendExternalModal> createState() => _SwapSendExternalModalState();
}

class _SwapSendExternalModalState extends State<SwapSendExternalModal> {
  PaymentURI? uri;
  bool largeQrMode = false;
  static const warningTextColor = Color(0xFFFFB84E);
  static const warningBackgroundColor = Color(0xFF8E5800);

  @override
  Widget build(BuildContext context) {
    if (widget.uri.address.isEmpty) {
      return const SizedBox.shrink();
    }
    final resolvedSize = MediaQuery.of(context).size.width * (largeQrMode ? 0.8 : 0.54);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        Navigator.of(context, rootNavigator: true).pop();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalTopBar(
                title: "",
                leadingWidget: SwapModalHeader(
                    fromIconPath: widget.from.iconPath ?? "", toIconPath: widget.to.iconPath ?? ""),
                trailingIcon: const Icon(Icons.close),
                onTrailingPressed: Navigator.of(context).pop,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  spacing: 24,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 12,
                      children: [
                        Text(
                          S.of(context).send_exactly,
                          style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500),
                        ),
                        Container(
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                spacing: 8,
                                children: [
                                  Text(
                                    widget.uri.amount,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.primary),
                                  ),
                                  Text(
                                    widget.from.title,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.primary),
                                  ),
                                ],
                              ),
                            )),
                        Text("${S.of(context).to}:",
                            style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500))
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          largeQrMode = !largeQrMode;
                        });
                      },
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(
                          begin: resolvedSize,
                          end: resolvedSize,
                        ),
                        builder: (context, animatedSize, child) => SizedBox(
                            width: animatedSize,
                            height: animatedSize,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: QrImage(
                                size: animatedSize,
                                embeddedImagePath: widget.from.iconPath,
                                data: uri?.toString() ?? widget.uri.address,
                              ),
                            ),
                          ),
                      ),
                    ),
                    AddressFormatter.buildSegmentedAddress(
                        address: widget.uri.address,
                        evenTextStyle: TextStyle(color: Theme
                            .of(context)
                            .colorScheme
                            .onSurface, fontFamily: "IBM Plex Mono", fontSize: 16),
                        textAlign: TextAlign.center),
                    Container(
                        decoration: BoxDecoration(
                          color: warningBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            S.of(context).send_external_desc,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: warningTextColor, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        )),
                    if (widget.extraId != null)
                      CopyWrapper(
                        data: ClipboardData(
                            text: widget.extraId!),
                        builder: (context, copied) => Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 8,
                              children: [
                                Text(
                                  S.of(context).destination_tag,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 8,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.extraId!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.primary),
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: Icon(
                                        copied ? Icons.check : Icons.copy,
                                        key: ValueKey(copied),
                                        size: 18,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Row(
                      spacing: 8,
                      children: [
                        Flexible(
                          child: NewPrimaryButton(
                              onPressed: () =>
                                  ClipboardUtil.copyToClipboard(context, widget.uri.address),
                              text: S.of(context).copy,
                              color: Theme.of(context).colorScheme.primary,
                              textColor: Theme.of(context).colorScheme.onPrimary),
                        ),
                        Flexible(
                          child: NewPrimaryButton(
                              onPressed: Navigator.of(context).pop,
                              text: S.of(context).sent_the_funds,
                              color: Theme.of(context).colorScheme.surfaceContainer,
                              textColor: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox()
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
