import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_footer.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_list_container.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_row.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/picker_section_header.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";

class StablecoinsPage extends StatefulWidget {
  const StablecoinsPage({
    required this.stablecoins,
    required this.selected,
    required this.symbolResolver,
    required this.pickNetwork,
    super.key,
  });

  final List<CryptoCurrency> stablecoins;
  final CryptoCurrency? selected;
  final String Function(CryptoCurrency) symbolResolver;
  final Future<CryptoCurrency?> Function(CryptoCurrency) pickNetwork;

  @override
  State<StablecoinsPage> createState() => _StablecoinsPageState();
}

class _StablecoinsPageState extends State<StablecoinsPage> {
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

  Future<void> _onTap(CryptoCurrency stablecoin) async {
    final picked = await widget.pickNetwork(stablecoin);
    if (picked != null && mounted) {
      Navigator.of(context).pop(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final matches = widget.stablecoins
        .where(
          (c) =>
              c.title.toLowerCase().contains(query) ||
              stablecoinNameForCurrency(c).toLowerCase().contains(query),
        )
        .toList(growable: false);
    final groups = groupStablecoins(matches);
    final selectedTitle = widget.selected?.title.toUpperCase();
    final footerHeight = CurrencyPickerFooter.heightFor(hasAction: false);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            ModalTopBar(
              testId: "stablecoins_page_top_bar",
              title: S.of(context).picker_section_stablecoins,
              leadingIcon: const Icon(Icons.arrow_back_ios_new),
              leadingSemanticLabel: S.of(context).seed_alert_back,
              onLeadingPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Stack(
                children: [
                  if (matches.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, footerHeight),
                        child: Text(
                          S.of(context).picker_no_matches,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    )
                  else
                    ListView(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, footerHeight),
                      children: [
                        for (final (title, coins) in [
                          (S.of(context).picker_section_popular, groups.popular),
                          (S.of(context).picker_section_euro_stablecoins, groups.euro),
                          (S.of(context).other, groups.other),
                        ])
                          if (coins.isNotEmpty) ...[
                            PickerSectionHeader(title: title),
                            CurrencyPickerListContainer(
                              rows: [
                                for (final coin in coins)
                                  CurrencyPickerRow(
                                    currency: coin,
                                    assetName: stablecoinNameForCurrency(coin),
                                    isSelected: coin.title.toUpperCase() == selectedTitle,
                                    trailing: SymbolTrailing(
                                      currency: coin,
                                      symbolResolver: widget.symbolResolver,
                                    ),
                                    onTap: () => _onTap(coin),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                      ],
                    ),
                  CurrencyPickerFooter(searchController: _searchController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
