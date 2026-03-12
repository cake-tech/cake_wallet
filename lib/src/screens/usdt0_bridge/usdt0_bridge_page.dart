import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scrollable_with_bottom_section.dart';
import 'package:cake_wallet/utils/request_review_handler.dart';
import 'package:cake_wallet/view_model/usdt0_bridge/usdt0_bridge_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class USDT0BridgePage extends BasePage {
  USDT0BridgePage(this.viewModel);

  final USDT0BridgeViewModel viewModel;

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget)? get rootWrapper =>
      (context, scaffold) => GradientBackground(scaffold: scaffold);

  @override
  String get title => "USDT0 Bridge";

  @override
  Widget? trailing(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.history),
      onPressed: () => Navigator.of(context).pushNamed(Routes.usdt0BridgeHistory),
    );
  }

  @override
  Widget body(BuildContext context) {
    return _USDT0BridgeBody(viewModel: viewModel, childBuilder: _buildContent);
  }

  Widget _buildContent(BuildContext context) {
    return Observer(
      builder: (_) {
        if (!viewModel.canShowBridge) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                "No USDT0 tokens found",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }
        viewModel.ensureDefaultSelection();
        return ScrollableWithBottomSection(
          contentPadding: const EdgeInsets.only(bottom: 24),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _USDT0TokenSection(viewModel: viewModel),
              const SizedBox(height: 16),
              _USDT0DestinationSection(viewModel: viewModel),
              const SizedBox(height: 16),
              _USDT0AmountField(viewModel: viewModel),
              const SizedBox(height: 16),
              _USDT0RecipientField(viewModel: viewModel),
              const SizedBox(height: 16),
              _USDT0QuoteSection(viewModel: viewModel),
            ],
          ),
          bottomSection: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _USDT0GetQuoteButton(viewModel: viewModel),
                const SizedBox(height: 12),
                _USDT0BridgeButton(viewModel: viewModel),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _USDT0BridgeBody extends StatefulWidget {
  const _USDT0BridgeBody({
    required this.viewModel,
    required this.childBuilder,
  });

  final USDT0BridgeViewModel viewModel;
  final Widget Function(BuildContext context) childBuilder;

  @override
  State<_USDT0BridgeBody> createState() => _USDT0BridgeBodyState();
}

class _USDT0BridgeBodyState extends State<_USDT0BridgeBody> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.onBridgeSuccess = _showSuccessBottomSheet;
  }

  @override
  void dispose() {
    widget.viewModel.onBridgeSuccess = null;
    super.dispose();
  }

  void _showSuccessBottomSheet() {
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
            titleText: "Bridge initiated!",
            contentImage: 'assets/images/birthday_cake.png',
            content: "The bridging will take approximately 30 seconds to 3 "
                "minutes to complete.",
            doubleActionLeftButtonText: S.of(bottomSheetContext).close,
            doubleActionRightButtonText: "View status",
            onLeftActionButtonPressed: () {
              Navigator.of(bottomSheetContext).pop();
              widget.viewModel.clearBridgeSuccess();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  Routes.dashboard,
                  (route) => false,
                );
              }
              RequestReviewHandler.requestReview();
            },
            onRightActionButtonPressed: () {
              final transfer = widget.viewModel.lastCreatedBridgeTransfer;
              Navigator.of(bottomSheetContext).pop();
              widget.viewModel.clearBridgeSuccess();
              if (mounted && transfer != null) {
                Navigator.of(context).pushNamed(
                  Routes.usdt0BridgeDetail,
                  arguments: transfer,
                );
              }
            },
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.childBuilder(context);
}

class _USDT0TokenSection extends StatelessWidget {
  const _USDT0TokenSection({required this.viewModel});

  final USDT0BridgeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final tokens = viewModel.availableUSDT0Tokens;
        if (tokens.isEmpty) return const SizedBox();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Token",
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: DropdownButtonFormField<CryptoCurrency>(
                  value: viewModel.selectedToken ?? tokens.first,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  items: tokens
                      .map((t) => DropdownMenuItem<CryptoCurrency>(
                            value: t,
                            child: Text(
                              '${t.title} (${t.symbol})',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) viewModel.setSelectedToken(value);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _USDT0DestinationSection extends StatelessWidget {
  const _USDT0DestinationSection({required this.viewModel});

  final USDT0BridgeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Destination chain",
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Observer(
            builder: (_) {
              final chains = viewModel.availableDestinationChains;
              if (chains.isEmpty) return const SizedBox();
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: DropdownButtonFormField<int>(
                  value: viewModel.destinationChainId ?? chains.first.chainId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  items: chains
                      .map((c) => DropdownMenuItem<int>(
                            value: c.chainId,
                            child: Text(
                              '${c.name} (${c.shortCode})',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) viewModel.setDestinationChain(value);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _USDT0AmountField extends StatelessWidget {
  const _USDT0AmountField({required this.viewModel});

  final USDT0BridgeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final amountError = viewModel.amountError;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BaseTextFormField(
                initialValue: viewModel.amount,
                onChanged: viewModel.setAmount,
                hintText: "Amount",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              if (amountError != null) ...[
                const SizedBox(height: 8),
                Text(
                  amountError,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _USDT0RecipientField extends StatefulWidget {
  const _USDT0RecipientField({required this.viewModel});

  final USDT0BridgeViewModel viewModel;

  @override
  State<_USDT0RecipientField> createState() => _USDT0RecipientFieldState();
}

class _USDT0RecipientFieldState extends State<_USDT0RecipientField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.viewModel.recipientAddress);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    widget.viewModel.setRecipientAddress(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recipient address",
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          AddressTextField<CryptoCurrency>(
            controller: _controller,
            hasUnderlineBorder: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            options: [
              AddressTextFieldOption.paste,
              AddressTextFieldOption.qrCode,
            ],
            selectedCurrency: widget.viewModel.wallet.currency,
            onURIScanned: (_) {},
            placeholder: "Recipient address",
            textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _USDT0QuoteSection extends StatelessWidget {
  const _USDT0QuoteSection({required this.viewModel});

  final USDT0BridgeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        if (viewModel.quoteError != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              viewModel.quoteError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          );
        }
        if (viewModel.quote != null) {
          final nativeFee = viewModel.quote!.nativeFee;
          final currency = viewModel.wallet.currency;
          final feeStr = nativeFee > BigInt.zero
              ? '~${currency.formatAmount(nativeFee)} ${currency.title}'
              : '0';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Estimated fee(native): $feeStr',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}

class _USDT0GetQuoteButton extends StatelessWidget {
  const _USDT0GetQuoteButton({required this.viewModel});

  final USDT0BridgeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => LoadingPrimaryButton(
        onPressed: () => viewModel.loadQuote(),
        text: "Get quote",
        color: Theme.of(context).colorScheme.primary,
        textColor: Theme.of(context).colorScheme.onPrimary,
        isLoading: viewModel.isQuoteLoading,
        isDisabled: viewModel.amountError != null || viewModel.amount.isEmpty,
      ),
    );
  }
}

class _USDT0BridgeButton extends StatelessWidget {
  const _USDT0BridgeButton({required this.viewModel});

  final USDT0BridgeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final canBridge = viewModel.quote != null &&
            !viewModel.isExecuting &&
            viewModel.amount.isNotEmpty &&
            viewModel.recipientAddress.isNotEmpty &&
            viewModel.amountError == null;
        final executeError = viewModel.executeError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (executeError != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  executeError,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
            ],
            LoadingPrimaryButton(
              onPressed: () => viewModel.executeBridge(),
              text: "Bridge",
              color: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onPrimary,
              isLoading: viewModel.isExecuting,
              isDisabled: !canBridge,
            ),
          ],
        );
      },
    );
  }
}
