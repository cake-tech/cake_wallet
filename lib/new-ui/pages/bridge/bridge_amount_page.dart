import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/pages/bridge/bridge_history_page.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/utils/request_review_handler.dart';
import 'package:cake_wallet/new-ui/widgets/keyboard_hide_overlay.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/view_model/bridge/bridge_history_view_model.dart';
import 'package:cake_wallet/view_model/bridge/bridge_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class BridgeAmountPage extends StatefulWidget {
  const BridgeAmountPage({
    super.key,
    required this.bridgeViewModel,
    required this.bridgeHistoryViewModel,
    required this.initialToken,
  });

  final BridgeViewModel bridgeViewModel;
  final BridgeHistoryViewModel bridgeHistoryViewModel;

  final CryptoCurrency initialToken;

  @override
  State<BridgeAmountPage> createState() => _BridgeAmountPageState();
}

class _BridgeAmountPageState extends State<BridgeAmountPage> {
  late final TextEditingController _amountController;
  BridgeViewModel get bridgeViewModel => widget.bridgeViewModel;

  @override
  void initState() {
    super.initState();
    bridgeViewModel.applyInitialBridgeToken(widget.initialToken);
    bridgeViewModel.onBridgeSuccess = _showBridgeSuccessBottomSheet;

    _amountController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      bridgeViewModel.ensureFiatPriceForSelectedToken();
    });
  }

  void _showBridgeSuccessBottomSheet() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ctx = context;
      if (!ctx.mounted) return;

      await showModalBottomSheet<void>(
        context: ctx,
        isScrollControlled: true,
        builder: (BuildContext bottomSheetContext) {
          return InfoBottomSheet(
            footerType: FooterType.doubleActionButton,
            titleText: 'Bridge initiated!',
            contentImage: 'assets/images/birthday_cake.png',
            content: 'The bridging will take between 30 seconds and 3 '
                'minutes to complete.',
            doubleActionLeftButtonText: S.of(bottomSheetContext).close,
            doubleActionRightButtonText: 'View history',
            onLeftActionButtonPressed: () {
              bridgeViewModel.clearOnBridgeSuccess();
              Navigator.of(context, rootNavigator: true).pop();
              RequestReviewHandler.requestReview();
            },
            onRightActionButtonPressed: () {
              bridgeViewModel.clearOnBridgeSuccess();
              Navigator.of(context).popUntil((route) => route.isFirst);
              showMaterialModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (ctx) => BridgeHistoryPage(widget.bridgeHistoryViewModel),
              );
            },
          );
        },
      );
    });
  }

  @override
  void dispose() {
    bridgeViewModel.onBridgeSuccess = null;
    bridgeViewModel.setAmount('');
    _amountController.dispose();
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            ModalTopBar(
              title: 'Enter Amount',
              leadingIcon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onLeadingPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              trailingIcon: const Icon(Icons.calendar_month, size: 18),
              onTrailingPressed: () {
                Navigator.pushNamed(context, Routes.bridgeHistoryPage,
                    arguments: widget.bridgeHistoryViewModel);
              },
            ),
            Expanded(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Observer(
                    builder: (_) {
                      final canNext = bridgeViewModel.canProceedToDestinationNetwork;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(flex: 2),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: (constraints.maxWidth - 200)
                                            .clamp(40.0, constraints.maxWidth),
                                        minWidth: 40,
                                      ),
                                      child: TextFormField(
                                        controller: _amountController,
                                        maxLines: 1,
                                        onChanged: bridgeViewModel.setAmount,
                                        autovalidateMode: AutovalidateMode.always,
                                        validator: bridgeViewModel.decimalAmountValidator,
                                        keyboardType: TextInputType.numberWithOptions(
                                          signed: false,
                                          decimal: true,
                                        ),
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d*[.,]?\d*$'),
                                          ),
                                        ],
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: '0.00',
                                          hintStyle: theme.textTheme.displayMedium?.copyWith(
                                            fontWeight: FontWeight.w400,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        style: theme.textTheme.displayMedium?.copyWith(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 45,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      bridgeViewModel.selectedToken?.title ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.displayMedium?.copyWith(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 45,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              bridgeViewModel.fiatAmountFormatted.isEmpty
                                  ? ''
                                  : '~${bridgeViewModel.fiatAmountFormatted} ${bridgeViewModel.fiatCurrencyTitle}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 22,
                                letterSpacing: -0.11,
                              ),
                            ),
                          ),
                          if (bridgeViewModel.amountError != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              bridgeViewModel.amountError!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                          const Spacer(flex: 3),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: RichText(
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Available ',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 16,
                                          letterSpacing: -0.08,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '${bridgeViewModel.tokenBalanceFormatted} '
                                            '${bridgeViewModel.selectedToken?.title ?? ''}',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 16,
                                          letterSpacing: -0.08,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              TextButton(
                                style: TextButton.styleFrom(
                                  textStyle: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    letterSpacing: -0.07,
                                  ),
                                  foregroundColor: theme.colorScheme.primary,
                                  backgroundColor: theme.colorScheme.surfaceContainer,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(80),
                                  ),
                                ),
                                onPressed: () {
                                  bridgeViewModel.setMaxAmount();
                                  _amountController.text = bridgeViewModel.amount;
                                  _amountController.selection = TextSelection.collapsed(
                                    offset: _amountController.text.length,
                                  );
                                },
                                child: Text(S.of(context).max),
                              ),
                              const SizedBox(width: 10),
                              IgnorePointer(
                                ignoring: !canNext,
                                child: ModernButton(
                                  size: 48,
                                  backgroundColor: theme.colorScheme.primary,
                                  iconColor: theme.colorScheme.onPrimary,
                                  icon: Icon(Icons.arrow_forward, size: 25),
                                  onPressed: () {
                                    _amountController.clear();
                                    Navigator.pushNamed(
                                      context,
                                      Routes.bridgeDestinationNetworkPage,
                                      arguments: bridgeViewModel,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
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
