import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile_base.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    required this.amountFiat,
    required this.roundedTop,
    required this.roundedBottom,
    required this.direction,
    required this.pending,
    required this.bottomSeparator,
    this.asset,
  });

  final String title;
  final String date;
  final String amount;
  final String amountFiat;
  final bool roundedTop;
  final bool roundedBottom;
  final bool bottomSeparator;
  final TransactionDirection direction;
  final bool pending;
  final CryptoCurrency? asset;

  String _getDirectionIcon() {
    if (pending) {
      return direction == TransactionDirection.incoming
          ? 'assets/new-ui/history-receiving.svg'
          : 'assets/new-ui/history-sending.svg';
    } else {
      return direction == TransactionDirection.incoming
          ? 'assets/new-ui/history-received.svg'
          : 'assets/new-ui/history-sent.svg';
    }
  }

  Widget _getLeadingIcon(BuildContext context) {
    if (asset == CryptoCurrency.btcln) {
      return Stack(
        children: [
          Image.asset(
            asset!.iconPath!,
            width: 34,
            height: 34,
          ),
          Positioned(
            top: 20,
            left: 20,
            child: SvgPicture.asset(
                'assets/new-ui/chain_badges/lightning.svg',
                width: 16,
                height: 16,
              ),
          )
        ],
      );
    }

    return SvgPicture.asset(_getDirectionIcon());
  }

  @override
  Widget build(BuildContext context) {
    return HistoryTileBase(
      title: title,
      date: date,
      amount: amount,
      amountFiat: amountFiat,
      leadingIcon: _getLeadingIcon(context),
      roundedTop: roundedTop,
      roundedBottom: roundedBottom,
      bottomSeparator: bottomSeparator,
      asset: asset,
    );
  }
}
