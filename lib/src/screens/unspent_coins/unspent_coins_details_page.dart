import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/coin_control/coin_control_bloc.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/screens/transaction_details/widgets/textfield_list_row.dart";
import "package:cake_wallet/src/screens/unspent_coins/widgets/unspent_coins_switch_row.dart";
import "package:cake_wallet/src/widgets/list_row.dart";
import "package:cake_wallet/utils/show_bar.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:url_launcher/url_launcher.dart";

class UnspentCoinsDetailsPage extends StatelessWidget {
  const UnspentCoinsDetailsPage({required this.rowId, required this.bloc});

  final String rowId;
  final CoinControlBloc bloc;

  @override
  Widget build(BuildContext context) => BlocBuilder<CoinControlBloc, CoinControlState>(
        bloc: bloc,
        builder: (context, state) {
          if(state is! CoinControlLoaded) {
            return const Center(child: CupertinoActivityIndicator());
          }

          final row = state.rowFor(rowId)!;

          return Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Column(
                children: [
                  ModalTopBar(
                    title: S.of(context).unspent_coins_details_title,
                    leadingIcon: const Icon(Icons.arrow_back_ios_new),
                    onLeadingPressed: Navigator.of(context).pop,
                    leadingSemanticLabel: S.of(context).seed_alert_back,
                  ),
                  Expanded(
                    child: Column(
                    children: [
                      _row(context, S.of(context).transaction_details_amount, "${row.amount.toString()} ${bloc.wallet.currency.symbol}"),
                      _row(context, S.of(context).transaction_details_transaction_id, row.txHash),
                      _row(context, S.of(context).widgets_address, row.address),
                      TextFieldListRow(
                        title: S.of(context).note_tap_to_change,
                        value: row.note,
                        onSubmitted: (value) {
                          bloc.add(NoteChanged(row.id, note: value));
                        },
                      ),
                      UnspentCoinsSwitchRow(
                        title: S.of(context).freeze,
                        switchValue: row.isFrozen,
                        onSwitchValueChange: (value) {
                          bloc.add(FreezeToggled(row.id, value: value));
                        },
                      ),
                      if (bloc.wallet.coinControlUrl(row.txHash) != null)
                        GestureDetector(
                          child: ListRow(
                            onTap: () {
                              try {
                                launchUrl(bloc.wallet.coinControlUrl(row.txHash)!);
                              } catch (_) {}
                            },
                            title: S.of(context).view_in_block_explorer,
                            value:
                                "${S.of(context).view_transaction_on}${bloc.wallet.coinControlUrl(row.txHash)!.authority}",
                          ),
                        ),
                    ],
                            ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _row(BuildContext context, String title, String value) => ListRow(
        onTap: () => _copy(
          context,
          title,
          value,
        ),
        title: title,
        value: value,
      );

  void _copy(BuildContext context, String title, String text) {
    Clipboard.setData(ClipboardData(text: text));
    showBar<void>(context, S.of(context).transaction_details_copied(title));
  }
}
