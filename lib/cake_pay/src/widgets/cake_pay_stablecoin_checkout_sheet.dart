import "dart:async";

import "package:cake_wallet/cake_pay/src/models/cake_pay_order.dart";
import "package:cake_wallet/cake_pay/src/services/cake_pay_api.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/stablecoin_checkout/stablecoin_checkout_bloc.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/chain_chip_strip.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cake_wallet/new-ui/widgets/line_tab_switcher.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/receive/widgets/qr_image.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/src/widgets/warning_box_widget.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:cake_wallet/utils/address_formatter.dart";
import "package:cake_wallet/utils/date_formatter.dart";
import "package:cake_wallet/utils/feature_flag.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class CakePayStablecoinCheckoutSheet extends StatelessWidget {
  const CakePayStablecoinCheckoutSheet(this.order, {super.key});

  final CakePayOrder order;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt.get<StablecoinCheckoutBloc>(param1: order),
        child: BlocConsumer<StablecoinCheckoutBloc, StablecoinCheckoutState>(
          listenWhen: (_, state) =>
              state is StablecoinCheckoutQuoteExpired ||
              state is StablecoinCheckoutOrderExpired ||
              state is StablecoinCheckoutOrderStatusChanged,
          listener: (context, state) {
            final route = ModalRoute.of(context)!;
            if (!route.isActive) {
              return;
            }
            final navigator = Navigator.of(context)..popUntil((current) => current == route);
            if (state is StablecoinCheckoutOrderStatusChanged) {
              navigator.pop(state.orderRecord);
            }
          },
          builder: (context, state) => DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ModalTopBar(
                    title: CakePayPaymentMethod.STABLECOIN.label,
                    trailingIcon: const Icon(Icons.close),
                    trailingSemanticLabel: S.of(context).close,
                    onTrailingPressed: Navigator.of(context).pop,
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 16,
                        children: [
                          ..._buildPicker(context, state),
                          ..._buildQuoteSection(context, state),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  List<Widget> _buildPicker(BuildContext context, StablecoinCheckoutState state) {
    final checkoutBloc = context.read<StablecoinCheckoutBloc>();
    final coins = checkoutBloc.coins;

    return [
      if (coins.length > 1)
        LineTabSwitcher(
          tabs: [for (final coin in coins) coin.paymentMethod],
          selectedTab: coins.indexOf(state.coin),
          onTabChange: (index) => checkoutBloc.add(CoinSelected(coins[index])),
        ),
      Text(
        S.of(context).select_network,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      Wrap(
        runSpacing: 8,
        children: [
          for (final network in state.coin.networks)
            SizedBox(
              height: 40,
              child: ChainChip(
                label: network.name,
                iconPath: _networkIconPath(network),
                isSelected: network == state.network,
                onTap: () => checkoutBloc.add(NetworkSelected(network)),
              ),
            ),
        ],
      ),
    ];
  }

  List<Widget> _buildQuoteSection(BuildContext context, StablecoinCheckoutState state) {
    final colors = Theme.of(context).colorScheme;

    return switch (state) {
      StablecoinCheckoutReady() || StablecoinCheckoutOrderStatusChanged() => [],
      StablecoinCheckoutLoading() => [const CupertinoActivityIndicator()],
      StablecoinCheckoutFailure(:final message) => [_warning(context, message)],
      StablecoinCheckoutOrderExpired() => [
          Text(S.of(context).expired, textAlign: TextAlign.center),
        ],
      StablecoinCheckoutQuoteExpired() => [
          Text(S.of(context).expired, textAlign: TextAlign.center),
          NewPrimaryButton(
            onPressed: () => context.read<StablecoinCheckoutBloc>().add(const NewQuoteRequested()),
            text: S.of(context).get_new_quote,
            color: colors.primary,
            textColor: colors.onPrimary,
          ),
        ],
      StablecoinCheckoutQuoted() => _buildQuote(context, state),
    };
  }

  List<Widget> _buildQuote(BuildContext context, StablecoinCheckoutQuoted state) {
    final colors = Theme.of(context).colorScheme;
    final quote = state.quote;
    final coin = state.coin;
    final amount = "${quote.amount} ${coin.paymentMethod}";

    return [
      Center(
        child: _Qr(
          data: quote.paymentRequest,
          iconPath: coin.currency.iconPath,
          badgePath: _networkIconPath(state.network),
        ),
      ),
      _warning(context, S.of(context).cake_pay_stablecoin_warning(amount, quote.chainName)),
      NewListSections(
        sections: {
          "": [
            ListItemRegularRow(
              keyValue: "amount",
              label: coin.currency.fullName ?? coin.paymentMethod,
              truncateLabel: true,
              iconPath: coin.currency.iconPath,
              badgeIconPath: state.network?.currency?.chainIconPath,
              trailingText: amount,
              trailingIconPath: "assets/new-ui/copy.svg",
              copyableText: quote.amount,
              showArrow: false,
            ),
            ListItemRegularRow(
              keyValue: "address",
              label: S.of(context).address,
              trailingIconPath: "assets/new-ui/copy.svg",
              copyableText: quote.address,
              showArrow: false,
              bottomWidget: AddressFormatter.buildSegmentedAddress(
                address: quote.address,
                evenTextStyle: TextStyle(
                  fontSize: 12,
                  fontFamily: "IBM Plex Mono",
                  color: colors.onSurface,
                ),
              ),
            ),
          ],
        },
      ),
      _Countdown(
        label: S.of(context).cake_pay_stablecoin_fee("${quote.fee} ${coin.paymentMethod}"),
        deadline: state.deadline,
      ),
      if (FeatureFlag.hasDevOptions &&
          FeatureFlag.isCakePayPurchaseSimulationEnabled &&
          CakePayApi.testBaseUri)
        NewPrimaryButton(
          onPressed: () =>
              context.read<StablecoinCheckoutBloc>().add(const PaymentSimulationRequested()),
          text: "(Dev) Simulate Payment",
          color: colors.primary,
          textColor: colors.onPrimary,
        ),
      if (state.canPayInCakeWallet)
        NewPrimaryButton(
          onPressed: () => Navigator.of(context).pushNamed(
            Routes.send,
            arguments: {"paymentRequest": state.paymentRequest},
          ),
          text: S.of(context).pay_in_cake_wallet,
          color: colors.primary,
          textColor: colors.onPrimary,
        ),
    ];
  }

  Widget _warning(BuildContext context, String text) => WarningBox(
        content: text,
        padding: const EdgeInsets.all(16),
        showBorder: false,
        textWeight: FontWeight.w500,
        textAlign: TextAlign.start,
        textColor: context.customColors.warningOutlineColor,
        iconSize: 22,
        iconSpacing: 16,
      );

  String? _networkIconPath(StablecoinNetwork? network) {
    final currency = network?.currency;
    return currency == null ? null : networkIconPathForCurrency(currency);
  }
}

class _Qr extends StatefulWidget {
  const _Qr({required this.data, this.iconPath, this.badgePath});

  final String data;
  final String? iconPath;
  final String? badgePath;

  @override
  State<_Qr> createState() => _QrState();
}

class _QrState extends State<_Qr> {
  bool _largeQrMode = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width * (_largeQrMode ? 0.8 : 0.54);

    return MergeSemantics(
      child: Semantics(
        hint: _largeQrMode ? S.of(context).qr_close_fullscreen : S.of(context).qr_fullscreen,
        button: true,
        enabled: true,
        child: GestureDetector(
          onTap: () => setState(() => _largeQrMode = !_largeQrMode),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: size, end: size),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, animatedSize, child) => ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: QrImage(
                data: widget.data,
                size: animatedSize,
                embeddedImagePath: widget.iconPath,
                badgeImageOnEmbeddedImagePath: widget.badgePath,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Countdown extends StatefulWidget {
  const _Countdown({required this.label, required this.deadline});

  final String label;
  final DateTime deadline;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.deadline.difference(DateTime.now());
    final time = DateFormatter.formatDuration(remaining.isNegative ? Duration.zero : remaining);

    return Text(
      "${widget.label}\n${S.of(context).offer_expires_in.trim()} $time",
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
