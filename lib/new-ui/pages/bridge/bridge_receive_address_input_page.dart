import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/pages/bridge/bridge_confirm_sheet.dart';
import 'package:cake_wallet/new-ui/widgets/keyboard_hide_overlay.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_address_input.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/view_model/bridge/bridge_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class BridgeReceiveAddressInputPage extends StatefulWidget {
  const BridgeReceiveAddressInputPage({super.key, required this.bridgeViewModel});

  final BridgeViewModel bridgeViewModel;

  @override
  State<BridgeReceiveAddressInputPage> createState() => _BridgeReceiveAddressInputPageState();
}

class _BridgeReceiveAddressInputPageState extends State<BridgeReceiveAddressInputPage> {
  BridgeViewModel get bridgeViewModel => widget.bridgeViewModel;

  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardHideOverlay(
      unfocusOnTap: true,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            ModalTopBar(
              title: 'Input Receive Address',
              leadingIcon: const Icon(Icons.arrow_back_ios_new, size: 18),
              leadingSemanticLabel: S.of(context).seed_alert_back,
              onLeadingPressed: () => Navigator.of(context).pop(),
            ),
            SizedBox(height: 48),
            Expanded(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Observer(
                        builder: (_) {
                          final chainName = bridgeViewModel.destinationChainInfo?.name;

                          return Column(
                            children: [
                              Text(
                                'Make sure it is compatible with:',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.07,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CakeImageWidget(
                                    imageUrl:
                                        'assets/new-ui/chain_badges/${chainName?.toLowerCase()}.svg',
                                    width: 24,
                                    height: 24,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    chainName ?? '',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: -0.07,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      NewSendAddressInput(
                        hintText: 'Enter Address',
                        addressController: _controller,
                        focusNode: _focusNode,
                        selectedCurrency: bridgeViewModel.wallet.currency,
                        onEditingComplete: () {},
                        validator:
                            AddressValidator(type: bridgeViewModel.destinationChainInfo!.currency),
                      ),
                      const Spacer(),
                      Observer(
                        builder: (_) {
                          return FilledButton(
                            onPressed: () {
                              final overlayCtx = Navigator.of(context).overlay?.context;
                              bridgeViewModel.setRecipientAddress(_controller.text.trim());

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (overlayCtx != null && overlayCtx.mounted) {
                                  showMaterialModalBottomSheet<void>(
                                    context: overlayCtx,
                                    backgroundColor: Colors.transparent,
                                    builder: (ctx) => BridgeConfirmSheet(bridgeViewModel),
                                  );
                                }
                              });
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(S.of(context).continue_text),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
