import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile_base.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_direction.dart";
import "package:flutter/material.dart";

class HistoryTile extends StatelessWidget {
  const HistoryTile({
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
    super.key,
  });

  final String title;
  final String date;
  final Money amount;
  final Money? amountFiat;
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
          ? "assets/new-ui/history-receiving.svg"
          : "assets/new-ui/history-sending.svg";
    } else {
      return direction == TransactionDirection.incoming
          ? "assets/new-ui/history-received.svg"
          : "assets/new-ui/history-sent.svg";
    }
  }

  String _getDirectionIconToken() {
    if (pending) {
      return direction == TransactionDirection.incoming
          ? "assets/new-ui/history-receiving.svg"
          : "assets/new-ui/history-sending.svg";
    } else {
      return direction == TransactionDirection.incoming
          ? "assets/new-ui/token-received.svg"
          : "assets/new-ui/token-sent.svg";
    }
  }

  Widget _getLeadingIcon(BuildContext context) {
    if (asset == CryptoCurrency.btcln) {
      return Stack(
        children: [
          const CakeImageWidget(
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
                color: Theme.of(context).colorScheme.onInverseSurface,
                shape: BoxShape.circle,
              ),
              child: CakeImageWidget(
                imageUrl: _getDirectionIconToken(),
                height: 14,
                width: 14,
                colorFilter: ColorFilter.mode(
                  direction == TransactionDirection.outgoing
                      ? Theme.of(context).colorScheme.inverseSurface.withAlpha(175)
                      : Colors.green,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (hasTokens) {
      return Stack(
        children: [
          Opacity(
            opacity: pending ? 0.5 : 1,
            child: TokenImageWidget(
              imageUrl: asset?.iconPath ?? "",
              size: 34,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: const BorderSide(color: Colors.black),
                ),
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: CakeImageWidget(
                  imageUrl: chainIconPath,
                  width: 12,
                  height: 12,
                  colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return CakeImageWidget(
      imageUrl: _getDirectionIcon(),
      colorFilter: ColorFilter.mode(
        direction == TransactionDirection.outgoing
            ? Theme.of(context).colorScheme.inverseSurface.withAlpha(175)
            : Colors.green,
        BlendMode.srcIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => HistoryTileBase(
        title: title,
        date: date,
        amount: amount,
        amountFiat: amountFiat ?? Money.zero(amount.currency),
        // Decorative: `title` already reads out sent/received/pending.
        leadingIcon: ExcludeSemantics(child: _getLeadingIcon(context)),
        roundedTop: roundedTop,
        roundedBottom: roundedBottom,
        bottomSeparator: bottomSeparator,
        asset: asset,
      );
}
