import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/coin_control/coin_control_bloc.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/screens/transaction_details/widgets/textfield_list_row.dart";
import "package:cake_wallet/src/screens/unspent_coins/widgets/unspent_coins_switch_row.dart";
import "package:cake_wallet/src/widgets/list_row.dart";
import "package:cake_wallet/utils/show_bar.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:url_launcher/url_launcher.dart";

class UnspentCoinsDetailsPage extends BasePage {
  UnspentCoinsDetailsPage({required this.rowId, required this.bloc});

  @override
  String get title => S.current.unspent_coins_details_title;

  final String rowId;
  final CoinControlBloc bloc;

  @override
  Widget body(BuildContext context) => BlocBuilder<CoinControlBloc, CoinControlState>(
        bloc: bloc,
        builder: (context, state) {
          if(state is! CoinControlLoaded) {
            return const Center(child: CupertinoActivityIndicator());
          }

          final row = state.rowFor(rowId)!;

          return Column(
          children: [
            _row(context, S.of(context).transaction_details_amount, row.amount.toString()),
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
