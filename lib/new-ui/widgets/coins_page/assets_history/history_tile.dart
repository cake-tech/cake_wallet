import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile_base.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
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
    required this.hasTokens,
    this.chainIconPath,
    this.asset,
  });

  final String title;
  final String date;
  final String amount;
  final String amountFiat;
  final bool roundedTop;
  final bool roundedBottom;
  final bool bottomSeparator;
  final bool hasTokens;
  final String? chainIconPath;
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

  String _getDirectionIconToken() {
    if (pending) {
      return direction == TransactionDirection.incoming
          ? 'assets/new-ui/history-receiving.svg'
          : 'assets/new-ui/history-sending.svg';
    } else {
      return direction == TransactionDirection.incoming
          ? 'assets/new-ui/token-received.svg'
          : 'assets/new-ui/token-sent.svg';
    }
  }

  Color? _getPrimaryTextColor() {}

  Widget _getLeadingIcon(BuildContext context) {
    if (asset == CryptoCurrency.btcln) {
      return Stack(
        children: [
          CakeImageWidget(
            imageUrl: "assets/new-ui/lightning-icon.svg",
            width: 34,
            height: 34,
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onInverseSurface, shape: BoxShape.circle),
              child: CakeImageWidget(
                imageUrl: _getDirectionIconToken(),
                height: 14,
                width: 14,
                colorFilter: ColorFilter.mode(
                    direction == TransactionDirection.outgoing
                        ? Theme.of(context).colorScheme.inverseSurface.withAlpha(175)
                        : Colors.green,
                    BlendMode.srcIn),
              ),
            ),
          )
        ],
      );
    }

    if (hasTokens) {
      return Stack(
        children: [
          Opacity(
            opacity: pending ? 0.5 : 1,
            child: CakeImageWidget(
              imageUrl: asset?.iconPath ?? "",
              width: 34,
            ),
          ),
          Align(
              alignment: Alignment.bottomRight,
              child: Container(
                  decoration: ShapeDecoration(
                      shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(5),
                          side: BorderSide(color: Colors.black)),
                      color: Colors.white),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: CakeImageWidget(
                      imageUrl: chainIconPath,
                      width: 12,
                      height: 12,
                      colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                    ),
                  )))
        ],
      );
    }

    return CakeImageWidget(
        imageUrl: _getDirectionIcon(),
        colorFilter: ColorFilter.mode(
            direction == TransactionDirection.outgoing
                ? Theme.of(context).colorScheme.inverseSurface.withAlpha(175)
                : Colors.green,
            BlendMode.srcIn));
  }

  @override
  Widget build(BuildContext context) {
    return HistoryTileBase(
      title: title,
      date: date,
      amount: amount,
      amountFiat: amountFiat,
      // Decorative: `title` already reads out sent/received/pending.
      leadingIcon: ExcludeSemantics(child: _getLeadingIcon(context)),
      primaryTextColor: _getPrimaryTextColor(),
      roundedTop: roundedTop,
      roundedBottom: roundedBottom,
      bottomSeparator: bottomSeparator,
      asset: asset,
    );
  }
}
