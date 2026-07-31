import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/pages/bridge/bridge_history_page.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/utils/request_review_handler.dart';
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
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  bool _amountFocused = false;

  BridgeViewModel get bridgeViewModel => widget.bridgeViewModel;

  @override
  void initState() {
    super.initState();
    bridgeViewModel.applyInitialBridgeToken(widget.initialToken);
    bridgeViewModel.onBridgeSuccess = _showBridgeSuccessBottomSheet;

    _amountFocusNode.addListener(() => setState(() => _amountFocused = _amountFocusNode.hasFocus));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      bridgeViewModel.ensureFiatPriceForSelectedToken();
      _amountFocusNode.requestFocus();
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
    bridgeViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            ModalTopBar(
              title: S.of(context).enter_amount,
              leadingIcon: Icon(Icons.arrow_back_ios_new),
              leadingSemanticLabel: S.of(context).seed_alert_back,
              onLeadingPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              trailingIcon: Icon(Icons.history),
              trailingSemanticLabel: S.of(context).history,
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
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                IntrinsicWidth(
                                  child: TextFormField(
                                    controller: _amountController,
                                    focusNode: _amountFocusNode,
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
                                    decoration: InputDecoration(
                                      isDense: true,
                                      isCollapsed: true,
                                      contentPadding: EdgeInsets.zero,
                                      fillColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      hintText: _amountFocused || _amountController.text.isNotEmpty
                                          ? null
                                          : "0.00",
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
                            spacing: 8,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                  child: Row(
                                spacing: 8,
                                children: [
                                  Text(
                                    S.of(context).available,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                  Text(
                                    "${bridgeViewModel.tokenBalanceFormatted} ${bridgeViewModel.selectedToken?.title ?? ""}",
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.onSurface),
                                  )
                                ],
                              )),
                              GestureDetector(
                                onTap: () {
                                  bridgeViewModel.setMaxAmount();
                                  _amountController.text = bridgeViewModel.amount;
                                  _amountController.selection = TextSelection.collapsed(
                                    offset: _amountController.text.length,
                                  );
                                },
                                child: Container(
                                  height: 34,
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainer,
                                      borderRadius: BorderRadius.circular(999999)),
                                  child: Center(
                                      child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      S.of(context).max,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.primary),
                                    ),
                                  )),
                                ),
                              ),
                              IgnorePointer(
                                ignoring: !canNext,
                                child: ModernButton(
                                  size: 34,
                                  backgroundColor: theme.colorScheme.primary,
                                  iconColor: theme.colorScheme.onPrimary,
                                  icon: Icon(Icons.arrow_forward, size: 20),
                                  semanticLabel: S.of(context).continue_text,
                                  onPressed: () {
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
                          SizedBox(height: 24)
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
