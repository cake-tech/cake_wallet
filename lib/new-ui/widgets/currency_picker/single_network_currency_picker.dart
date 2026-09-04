import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_footer.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_list_container.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_row.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_search_field.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/picker_section_header.dart";
import "package:cake_wallet/reactions/wallet_utils.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";

class SingleNetworkCurrencyPicker extends StatefulWidget {
  const SingleNetworkCurrencyPicker({
    required this.args,
    this.onSendAnotherAsset,
    super.key,
  });

  final CurrencyPickerArgs args;
  final VoidCallback? onSendAnotherAsset;

  @override
  State<SingleNetworkCurrencyPicker> createState() => _SingleNetworkCurrencyPickerState();
}

class _SingleNetworkCurrencyPickerState extends State<SingleNetworkCurrencyPicker> {
  CurrencyPickerArgs get _args => widget.args;
  WalletType get _network => _args.filterByNetwork!;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCurrency(CryptoCurrency currency) {
    _args.onSelected(currency);
    Navigator.of(context).maybePop();
  }

  double _fiatValueFor(CryptoCurrency c) =>
      balanceForAsset(_args.balanceByAsset, c)?.fiatValue ?? 0;

  @override
  Widget build(BuildContext context) {
    final native = walletTypeToCryptoCurrency(_network);
    final query = _searchController.text.trim();
    final tokens = _args.items
        .where(
          (c) =>
              c != native &&
              cryptoCurrencyOrTokenToWalletType(c) == _network &&
              currencyMatchesQuery(c, query),
        )
        .toList();

    final insertOrder = {for (var i = 0; i < tokens.length; i++) tokens[i]: i};
    tokens.sort((a, b) {
      final av = _fiatValueFor(a);
      final bv = _fiatValueFor(b);
      if (bv != av) {
        return bv.compareTo(av);
      }
      return (insertOrder[a] ?? 0).compareTo(insertOrder[b] ?? 0);
    });
    final nativeMatches = currencyMatchesQuery(native, query);

    final walletName = _args.walletName;
    final onSendAnotherAsset = widget.onSendAnotherAsset;
    final footerHeight = CurrencyPickerFooter.heightFor(hasAction: onSendAnotherAsset != null);

    return Stack(
      children: [
        (nativeMatches || tokens.isNotEmpty)
            ? ListView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, footerHeight),
                children: [
                  if (walletName != null) ...[
                    _FromWalletHeader(walletName: walletName),
                    const SizedBox(height: 24),
                  ],
                  if (hasTokens(_network)) ...[
                    if (nativeMatches) ...[
                      PickerSectionHeader(title: S.of(context).picker_section_gas_token),
                      CurrencyPickerListContainer(
                        rows: [
                          _WalletAssetRow(args: _args, currency: native, onTap: _selectCurrency),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (tokens.isNotEmpty) ...[
                      PickerSectionHeader(
                        title: S
                            .of(context)
                            .picker_section_tokens_standard(tokenStandardFor(_network)),
                      ),
                      CurrencyPickerListContainer(
                        rows: [
                          for (final t in tokens)
                            _WalletAssetRow(args: _args, currency: t, onTap: _selectCurrency),
                        ],
                      ),
                    ],
                  ] else
                    CurrencyPickerListContainer(
                      rows: [
                        if (nativeMatches)
                          _WalletAssetRow(args: _args, currency: native, onTap: _selectCurrency),
                        for (final t in tokens)
                          _WalletAssetRow(args: _args, currency: t, onTap: _selectCurrency),
                      ],
                    ),
                ],
              )
            : Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, footerHeight),
                child: Center(
                  child: Text(
                    S.of(context).picker_no_matches,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
        CurrencyPickerFooter(
          searchController: _searchController,
          action: onSendAnotherAsset == null
              ? null
              : _SendAnotherAssetButton(onTap: onSendAnotherAsset),
        ),
      ],
    );
  }
}

class _FromWalletHeader extends StatelessWidget {
  const _FromWalletHeader({required this.walletName});

  final String walletName;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Row(
          children: [
            Text(
              S.of(context).from,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: -0.06),
            ),
            const SizedBox(width: 8),
            ExcludeSemantics(
              child: CakeImageWidget(
                imageUrl: "assets/new-ui/wallet_filled.svg",
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                walletName,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.06,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      );
}

class _WalletAssetRow extends StatelessWidget {
  const _WalletAssetRow({
    required this.args,
    required this.currency,
    required this.onTap,
  });

  final CurrencyPickerArgs args;
  final CryptoCurrency currency;
  final void Function(CryptoCurrency) onTap;

  @override
  Widget build(BuildContext context) {
    final network = walletTypeToCryptoCurrency(args.filterByNetwork!);
    return CurrencyPickerRow(
      currency: currency,
      isSelected: args.selected == currency,
      subtitle: args.symbolResolver(currency),
      chainBadgePath: currency.chainIconPath ?? network.chainIconPath,
      trailing: _BalanceTrailing(balance: balanceForAsset(args.balanceByAsset, currency)),
      onTap: () => onTap(currency),
    );
  }
}

class _BalanceTrailing extends StatelessWidget {
  const _BalanceTrailing({required this.balance});

  final CurrencyPickerBalance? balance;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fiat = balance?.fiat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          balance?.amount ?? "—",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: -0.06),
        ),
        if (fiat != null && fiat.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            fiat,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: -0.06,
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

class _SendAnotherAssetButton extends StatelessWidget {
  const _SendAnotherAssetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Semantics(
          button: true,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: CakeImageWidget(
                      imageUrl: "assets/new-ui/send_another_asset.svg",
                      width: 24,
                      height: 24,
                      colorFilter:
                          ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    S.of(context).send_another_asset,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          letterSpacing: -0.07,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
