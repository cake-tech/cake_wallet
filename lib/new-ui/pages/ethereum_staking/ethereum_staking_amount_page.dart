import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/main.dart";
import "package:cake_wallet/new-ui/pages/ethereum_staking/ethereum_staking_confirm_page.dart";
import "package:cake_wallet/new-ui/viewmodels/ethereum_staking/ethereum_staking_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/widgets/floating_amount_input.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cw_core/amount/amount_sanitizer.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

enum EthereumStakingAmountMode { deposit, withdraw }

class EthereumStakingAmountPage extends StatefulWidget {
  const EthereumStakingAmountPage({required this.mode, required this.authService, super.key});

  final EthereumStakingAmountMode mode;
  final AuthService authService;

  @override
  State<EthereumStakingAmountPage> createState() => _EthereumStakingAmountPageState();
}

class _EthereumStakingAmountPageState extends State<EthereumStakingAmountPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  late final Currency _inputCurrency =
      context.read<FiatRateCubit>().state?.quote.currency ?? CryptoCurrency.eth;

  bool _useMax = false;
  bool _preparing = false;
  String? _prepareError;

  bool get _isDeposit => widget.mode == EthereumStakingAmountMode.deposit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<EthereumStakingBloc, EthereumStakingState>(
        listener: (context, state) {
          if (_useMax) {
            _syncMaxAmount(state.data!, context.read<FiatRateCubit>().state);
          }
          if (!_preparing) {
            return;
          }

          switch (state) {
            case EthereumStakingPrepared(:final operation):
              setState(() => _preparing = false);
              Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => Material(
                    color: Colors.transparent,
                    child: EthereumStakingConfirmPage(operation),
                  ),
                ),
              );
            case EthereumStakingFailure(:final error):
              setState(() {
                _preparing = false;
                _prepareError = error;
              });
            case EthereumStakingReady():
              setState(() => _preparing = false);
            default:
              break;
          }
        },
        builder: (context, state) => BlocConsumer<FiatRateCubit, ExchangeRate?>(
          listener: (context, fiatRate) {
            if (_useMax) {
              _syncMaxAmount(context.read<EthereumStakingBloc>().state.data!, fiatRate);
            }
          },
          builder: (context, fiatRate) {
            final theme = Theme.of(context);
            final locale = Localizations.localeOf(context).toString();
            final isBusy = state is EthereumStakingLoading || state is EthereumStakingPreparing;
            final data = state.data!;
            final maxAmount = _isDeposit ? data.walletBalance : data.withdrawableBalance;
            final amount = _useMax ? maxAmount : _parseAmount(fiatRate);
            final convertsToFiat = _inputCurrency == CryptoCurrency.eth;
            final converted =
                amount == null || !convertsToFiat ? amount : fiatRate?.convert(amount);
            final convertedStyle = TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            );
            final inputError = _hasTooManyDecimals ? S.of(context).decimal_places_error : null;
            final error = inputError ?? _prepareError;
            final maxLabel = _isDeposit
                ? S.of(context).max
                : data.withdrawsPendingStake
                    ? S.of(context).pending_activation
                    : S.of(context).staked;

            return Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                gradient: LinearGradient(
                  colors: [theme.colorScheme.surface, theme.colorScheme.surfaceDim],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    ModalTopBar(
                      title: S.of(context).enter_amount,
                      bottomText: "$maxLabel (${maxAmount.toLocalStringWithSymbol(
                        fractionalDigits: 8,
                        locale: locale,
                      )})",
                      leadingIcon: const Icon(Icons.close),
                      leadingSemanticLabel: S.of(context).close,
                      onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox.shrink(),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: Column(
                                spacing: 8,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: FloatingAmountInput(
                                      currency: _inputCurrency,
                                      controller: _controller,
                                      focusNode: _focusNode,
                                      onChanged: (_) => setState(() {
                                        _useMax = false;
                                        _prepareError = null;
                                      }),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: 8,
                                    children: [
                                      if (converted != null && _controller.text.isNotEmpty)
                                        Flexible(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text("≈ ", style: convertedStyle),
                                              Flexible(
                                                child: MoneyText(
                                                  converted,
                                                  isHiddenAmount: false,
                                                  fractionalDigits: convertsToFiat ? 2 : 8,
                                                  trimZeros: !convertsToFiat,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: convertedStyle,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      _MaxChip(
                                        label: _isDeposit
                                            ? S.of(context).max
                                            : S.of(context).all_pascal_case,
                                        onPressed: () => _fillMax(data, fiatRate),
                                      ),
                                    ],
                                  ),
                                  if (error != null)
                                    Text(
                                      error,
                                      textAlign: TextAlign.center,
                                      style:
                                          TextStyle(fontSize: 12, color: theme.colorScheme.error),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                spacing: 8,
                                children: [
                                  Text(
                                    _isDeposit
                                        ? S.of(context).min_amount(
                                              data.minStakeAmount
                                                  .toLocalStringWithSymbol(locale: locale),
                                            )
                                        : S.of(context).withdraw_all_or_partial,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  NewPrimaryButton(
                                    onPressed: () => _continue(data, amount!),
                                    isLoading: _preparing,
                                    disabled: (isBusy && !_preparing) ||
                                        inputError != null ||
                                        amount == null ||
                                        amount.sign <= 0,
                                    text: S.of(context).continue_text,
                                    color: theme.colorScheme.primary,
                                    textColor: theme.colorScheme.onPrimary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Money? _parseAmount(ExchangeRate? fiatRate) {
    final input = Money.tryParse(_controller.text.sanitized(), _inputCurrency);
    if (input == null || _inputCurrency == CryptoCurrency.eth) {
      return input;
    }

    return fiatRate?.convert(input);
  }

  bool get _hasTooManyDecimals {
    final parts = _controller.text.split(RegExp("[.,]"));
    return parts.length == 2 && parts.last.length > _inputCurrency.decimals;
  }

  void _syncMaxAmount(EthereumStakingData data, ExchangeRate? fiatRate) {
    final maxAmount = _isDeposit ? data.walletBalance : data.withdrawableBalance;
    final display = _inputCurrency == CryptoCurrency.eth ? maxAmount : fiatRate?.convert(maxAmount);
    if (display == null) {
      return;
    }

    final text = display.toStringWithPrecision(fractionalDigits: 8);
    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  void _fillMax(EthereumStakingData data, ExchangeRate? fiatRate) {
    if (_inputCurrency != CryptoCurrency.eth && fiatRate == null) {
      return;
    }

    _syncMaxAmount(data, fiatRate);
    setState(() {
      _useMax = true;
      _prepareError = null;
    });
  }

  void _continue(EthereumStakingData data, Money amount) {
    if (_isDeposit) {
      _prepare(_useMax ? const MaxStakeRequested() : StakeRequested(amount));
    } else {
      _prepare(
        data.withdrawsPendingStake ? PendingUnstakeRequested(amount) : UnstakeRequested(amount),
      );
    }
  }

  void _prepare(TransactionRequested event) {
    if (_preparing) {
      return;
    }

    final settings = widget.authService.settingsStore;
    widget.authService.authenticateAction(
      navigatorKey.currentContext ?? context,
      conditionToDetermineIfToUse2FA: _isDeposit
          ? settings.shouldRequireTOTP2FAForSendsToNonContact
          : settings.shouldRequireTOTP2FAForSendsToInternalWallets,
      onAuthSuccess: (authenticated) {
        if (!authenticated || !mounted) {
          return;
        }
        setState(() {
          _preparing = true;
          _prepareError = null;
        });
        context.read<EthereumStakingBloc>().add(event);
      },
    );
  }
}

class _MaxChip extends StatelessWidget {
  const _MaxChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Semantics(
          button: true,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: onPressed,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ),
          ),
        ),
      );
}
