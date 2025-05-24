import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/exchange/trade.dart';

class ExchangeConfirmPage extends BasePage {
  ExchangeConfirmPage({required this.tradesStore}) : trade = tradesStore.trade!;

  final TradesStore tradesStore;
  final Trade trade;

  @override
  String get title => S.current.swap;

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                Flexible(
                  child: Center(
                    child: Text(
                      S.of(context).exchange_result_write_down_trade_id,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
                Container(
                  height: 178,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    border: Border.all(
                      width: 0.0,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                "${trade.provider.title} ${S.of(context).trade_id}",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              Text(
                                trade.id,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: Builder(
                          builder: (context) => PrimaryButton(
                            key: ValueKey('exchange_confirm_page_copy_to_clipboard_button_key'),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: trade.id));
                              showBar<void>(context, S.of(context).copied_to_clipboard);
                            },
                            text: S.of(context).copy_id,
                            color: Theme.of(context).colorScheme.surfaceContainerLow,
                            textColor: Theme.of(context).colorScheme.onSurface,
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      if (trade.provider == ExchangeProviderDescription.trocador)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            S.of(context).selected_trocador_provider + ':${trade.providerName}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      Flexible(
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              (trade.provider.image.isNotEmpty)
                                  ? ImageUtil.getImageFromPath(
                                      imagePath: trade.provider.image, height: 50, width: 50)
                                  : const SizedBox(),
                              if (!trade.provider.horizontalLogo)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(trade.provider.title),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          PrimaryButton(
            key: ValueKey('exchange_confirm_page_saved_id_button_key'),
            onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.exchangeTrade),
            text: S.of(context).saved_the_trade_id,
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
          )
        ],
      ),
    );
  }
}
