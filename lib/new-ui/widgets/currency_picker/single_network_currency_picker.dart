import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_list_container.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_row.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_search_field.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/picker_section_header.dart';
import 'package:cake_wallet/reactions/wallet_utils.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class SingleNetworkCurrencyPicker extends StatefulWidget {
  const SingleNetworkCurrencyPicker({super.key, required this.args});

  final CurrencyPickerArgs args;

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

  @override
  Widget build(BuildContext context) {
    final native = walletTypeToCryptoCurrency(_network);
    final query = _searchController.text.trim();
    final tokens = _args.items
        .where((c) => c != native)
        .where((c) => currencyMatchesQuery(c, query))
        .toList(growable: false);
    final nativeMatches = currencyMatchesQuery(native, query);

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: (nativeMatches || tokens.isNotEmpty)
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    if (nativeMatches) ...[
                      PickerSectionHeader(title: S.of(context).picker_section_gas_token),
                      CurrencyPickerListContainer(
                        rows: [
                          CurrencyPickerRow(
                            currency: native,
                            isSelected: _args.selected != null && _args.selected!.raw == native.raw,
                            trailing: _BalanceTrailing(balance: _args.balanceByAsset?[native]),
                            onTap: () => _selectCurrency(native),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                            CurrencyPickerRow(
                              currency: t,
                              isSelected: _args.selected != null && _args.selected!.raw == t.raw,
                              trailing: _BalanceTrailing(balance: _args.balanceByAsset?[t]),
                              onTap: () => _selectCurrency(t),
                            ),
                        ],
                      ),
                    ],
                  ],
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      S.of(context).picker_no_matches,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
        ),
        CurrencyPickerSearchField(
          controller: _searchController,
          hintText: S.of(context).search,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _BalanceTrailing extends StatelessWidget {
  const _BalanceTrailing({required this.balance});

  final CurrencyPickerBalance? balance;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final amount = balance?.amount ?? '—';
    final fiat = balance?.fiat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        if (fiat != null && fiat.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              fiat,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }
}
