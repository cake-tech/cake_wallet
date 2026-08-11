import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/bridge/confirm_details_card.dart';
import 'package:cake_wallet/new-ui/widgets/bridge/network_path_pill.dart';
import 'package:cake_wallet/new-ui/widgets/confirm_swiper.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_confirm_bottom_widget.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/view_model/bridge/bridge_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class BridgeConfirmSheet extends StatefulWidget {
  const BridgeConfirmSheet(this.bridgeViewModel);

  final BridgeViewModel bridgeViewModel;

  @override
  State<BridgeConfirmSheet> createState() => _BridgeConfirmSheetState();
}

class _BridgeConfirmSheetState extends State<BridgeConfirmSheet> {
  late final ReactionDisposer _successDisposer;

  BridgeViewModel get bridgeViewModel => widget.bridgeViewModel;

  @override
  void initState() {
    super.initState();
    _successDisposer = reaction(
      (_) => bridgeViewModel.bridgeSuccess,
      (bool success) {
        if (success && mounted) {
          Navigator.of(context).maybePop();
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      bridgeViewModel.loadQuote();
      bridgeViewModel.ensureFiatPriceForSelectedToken();
      bridgeViewModel.ensureFiatPriceForNativeCurrency();
    });
  }

  @override
  void dispose() {
    _successDisposer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Observer(
              builder: (_) {
                return ModalTopBar(
                  title: '',
                  leadingWidget: Row(
                    spacing: 8,
                    children: [
                      CakeImageWidget(
                        imageUrl: bridgeViewModel.selectedToken?.iconPath ?? '',
                        width: 36,
                        height: 36,
                      ),
                      Text(
                        'Bridge',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                              letterSpacing: -0.1,
                              color: scheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                  trailingIcon: const Icon(Icons.close),
                  trailingSemanticLabel: S.of(context).close,
                  onTrailingPressed: () => Navigator.of(context).maybePop(),
                );
              },
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Observer(
                builder: (_) {
                  if (bridgeViewModel.isQuoteLoading && bridgeViewModel.quote == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CupertinoActivityIndicator(),
                      ),
                    );
                  }

                  if (bridgeViewModel.quoteError != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          Text(
                            bridgeViewModel.quoteError!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  letterSpacing: -0.07,
                                  color: scheme.error,
                                ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => bridgeViewModel.loadQuote(),
                            child: Text(
                              S.of(context).try_again,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    letterSpacing: -0.08,
                                    color: scheme.onPrimary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 24,
                    children: [
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 4,
                            children: [
                              Text(
                                bridgeViewModel.amountDisplayFormatted,
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w400,
                                      color: scheme.onSurface,
                                    ),
                              ),
                              Text(
                                bridgeViewModel.selectedToken?.title ?? '',
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w400,
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${bridgeViewModel.fiatCurrencyTitle} ${bridgeViewModel.fiatAmountFormatted}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: scheme.onSurfaceVariant,
                                  letterSpacing: -0.1,
                                ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NetworkPathPill(
                            sourceChainName: bridgeViewModel.wallet.type.name,
                            destChainName: bridgeViewModel.destinationChainInfo?.name ?? '',
                          ),
                        ],
                      ),
                      ConfirmDetailsCard(bridgeViewModel: bridgeViewModel),
                      if (bridgeViewModel.executeError != null) ...[
                        Text(
                          bridgeViewModel.executeError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.error),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Observer(
                builder: (_) {
                  if (bridgeViewModel.isExecuting) {
                    return LoadingBottomWidget(
                      text: "${S.of(context).bridging}...",
                    );
                  }
                  if (bridgeViewModel.isQuoteLoading || bridgeViewModel.quote == null) {
                    return LoadingBottomWidget(text: "${S.of(context).loading}...");
                  }
                  return ConfirmSwiper(
                    onConfirmed: () {
                      bridgeViewModel.executeBridge();
                    },
                    swiperText: S.of(context).swipe_to_bridge,
                    accessibleNavigationModeButtonText: S.of(context).confirm,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
