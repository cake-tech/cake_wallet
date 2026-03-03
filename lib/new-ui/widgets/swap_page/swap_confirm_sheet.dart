import 'package:cake_wallet/core/utilities.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_confirm_bottom_widget.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_confirm_sheet.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/swap_modal_header.dart';
import 'package:cake_wallet/new-ui/widgets/swap_page/swap_send_external_modal.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/connect_device/connect_device_page.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/exchange/exchange_trade_view_model.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class SwapConfirmSheet extends StatefulWidget {
  const SwapConfirmSheet(
      {super.key,
      required this.exchangeViewModel,
      required this.exchangeTradeViewModel,
      required this.receiveAmount});

  final ExchangeViewModel exchangeViewModel;
  final ExchangeTradeViewModel exchangeTradeViewModel;
  final String receiveAmount;

  @override
  State<SwapConfirmSheet> createState() => _SwapConfirmSheetState();
}

class _SwapConfirmSheetState extends State<SwapConfirmSheet> {

  void beginSend() async {
    final sendVM = widget.exchangeTradeViewModel.sendViewModel;

    if (sendVM.wallet.isHardwareWallet) {
      if (!sendVM.hardwareWalletViewModel!.isConnected) {
        await Navigator.of(context).pushNamed(Routes.connectDevices,
            arguments: ConnectDevicePageParams(
              walletType: sendVM.walletType,
              hardwareWalletType: sendVM.wallet.walletInfo.hardwareWalletType!,
              onConnectDevice: (context, _) {
                sendVM.hardwareWalletViewModel!.initWallet(sendVM.wallet);
                Navigator.of(context).pop();
              },
            ));
      } else {
        sendVM.hardwareWalletViewModel!.initWallet(sendVM.wallet);
      }
    }

    widget.exchangeTradeViewModel.confirmSending();
  }

  @override
  void initState() {
    super.initState();

    if (!widget.exchangeViewModel.isSendFromExternal) {
      beginSend();
    }

    reaction((context) => widget.exchangeTradeViewModel.sendViewModel.state, (state) {
      if (state is TransactionCommitted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        Navigator.of(context, rootNavigator: true).pop();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Observer(
            builder: (_) {
              final commited = widget.exchangeTradeViewModel.sendViewModel.state is TransactionCommitted;
              return Stack(
                fit: StackFit.loose,
                children: [
                  Positioned.fill(
                      child: AnimatedSlide(
                        offset: commited ? Offset.zero : const Offset(1, 0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: const TransactionCommitedScreen(),
                      )),
                  AnimatedSlide(
                    offset: commited ? const Offset(-1, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: SwapTransactionDetails(
                    exchangeViewModel: widget.exchangeViewModel,
                    exchangeTradeViewModel: widget.exchangeTradeViewModel,
                    receiveAmount: widget.receiveAmount,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
    ));
  }


}


class SwapTransactionDetails extends StatelessWidget {
  const SwapTransactionDetails({super.key, required this.exchangeViewModel, required this.exchangeTradeViewModel, required this.receiveAmount});

  final ExchangeViewModel exchangeViewModel;
  final ExchangeTradeViewModel exchangeTradeViewModel;
  final String receiveAmount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ModalTopBar(
          title: "",
          leadingWidget: SwapModalHeader(
              fromIconPath: exchangeViewModel.depositCurrency.iconPath ?? "",
              toIconPath: exchangeViewModel.receiveCurrency.iconPath ?? ""),
          trailingIcon: Icon(Icons.close),
          onTrailingPressed: Navigator.of(context).maybePop,
        ),
        SafeArea(
          top:false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              spacing: 24,
              children: [
                Observer(
                  builder: (_) => NewListSections(showHeader: true, sections: {
                    S.of(context).send: [
                      ListItemRegularRow(
                          showArrow: false,
                          keyValue: "send value",
                          label: exchangeViewModel.depositCurrency.fullName ?? "",
                          iconPath: exchangeViewModel.depositCurrency.iconPath ?? "",
                          trailingText: exchangeTradeViewModel.trade.amountFormatted() +
                              " " +
                              (exchangeViewModel.depositCurrency.title)),
                      if(exchangeTradeViewModel.sendViewModel.pendingTransaction != null)
                        ListItemRegularRow(
                            showArrow: false,
                            keyValue: "fee",
                            label: S.of(context).fee,
                            trailingText:
                            "${exchangeTradeViewModel.sendViewModel.pendingTransaction?.feeFormatted} (${exchangeTradeViewModel.pendingTransactionFeeFiatAmountFormatted})"),
                      ListItemRegularRow(
                          keyValue: "sender",
                          label: S.of(context).from,
                          trailingText: exchangeViewModel.isSendFromExternal
                              ? S.of(context).external_wallet
                              : exchangeViewModel.wallet.name,
                          showArrow: false)
                    ],
                    S.of(context).receive: [
                      ListItemRegularRow(
                          showArrow: false,
                          keyValue: "receive value",
                          label: exchangeViewModel.receiveCurrency.fullName ?? "",
                          iconPath: exchangeViewModel.receiveCurrency.iconPath ?? "",
                          trailingText: (receiveAmount) +
                              " " +
                              (exchangeViewModel.receiveCurrency.title)),
                      ListItemRegularRow(
                          keyValue: "receiver",
                          label: S.of(context).to,
                          showArrow: false,
                          trailingText: exchangeViewModel.receiveAddressDisplayName ?? middleTruncate(exchangeTradeViewModel.trade.payoutAddress ?? "", 8, 8))
                    ],
                    "${S.of(context).swap_id} (${S.of(context).tap_to_copy})": [
                      ListItemRegularRow(
                          showArrow: false,
                          keyValue: "provider",
                          onTap: () => Clipboard.setData(
                              ClipboardData(text: exchangeTradeViewModel.trade.id)),
                          label: exchangeTradeViewModel.trade.provider.title,
                          iconPath: exchangeTradeViewModel.trade.provider.image,
                          trailingIconPath: "assets/new-ui/copy.svg",
                          trailingText: exchangeTradeViewModel.trade.id,
                          truncateTrailingText: (exchangeTradeViewModel.trade.provider == ExchangeProviderDescription.swapsXyz)),
                      if(exchangeTradeViewModel.trade.provider == ExchangeProviderDescription.trocador)
                        ListItemRegularRow(
                            showArrow: false,
                            keyValue: "trocador provider name",
                            label: "Trocador ${S.of(context).provider}",
                            trailingText: exchangeTradeViewModel.trade.providerName??""
                        )
                    ]
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: exchangeViewModel.isSendFromExternal
                      ? NewPrimaryButton(
                      onPressed: ()=>_showExternalSendModal(context),
                      text: S.of(context).continue_text,
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary)
                      : SendConfirmBottomWidget(
                      sendViewModel: exchangeTradeViewModel.sendViewModel),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  void _showExternalSendModal(BuildContext context) {
    showMaterialModalBottomSheet(
        context: context,
        builder: (context) {
          return SwapSendExternalModal(
              amount: exchangeTradeViewModel.trade.amount,
              exchangeTradeViewModel: exchangeTradeViewModel,
              from: exchangeTradeViewModel.trade.from!,
              to: exchangeTradeViewModel.trade.to!,
              address: exchangeTradeViewModel.trade.inputAddress ?? "");
        });
  }

}
