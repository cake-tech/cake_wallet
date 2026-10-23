import "dart:async";

import "package:cake_wallet/core/open_crypto_pay/open_cryptopay_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/modal_navigator.dart";
import "package:cake_wallet/new-ui/pages/buy_sell/buy_sell_amount_page.dart";
import "package:cake_wallet/new-ui/pages/receive_page.dart";
import "package:cake_wallet/new-ui/pages/send_page.dart";
import "package:cake_wallet/new-ui/pages/swap_page.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/utils/payment_request.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/buy/buy_sell_view_model.dart";
import "package:cake_wallet/view_model/send/send_view_model.dart";
import "package:cw_core/lnurl.dart";
import "package:cw_core/node.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:flutter/material.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

final _links = <String, AppLink Function(Uri)>{
  "wc": WalletConnectLink.new,
  // this has to be here due to deep linking from the wc browser popup (ex. cakewallet://wc?uri=something)
  "cakewallet": WalletConnectLink.new,
  "quickaction": QuickActionLink.new,
  "nano-gpt": NanoGptLink.new,
  "http": NodeLink.new,
  "https": NodeLink.new,
  "tcp": NodeLink.new,
};

AppLink appLinkFor(Uri uri) => _links[uri.scheme]?.call(uri) ?? PaymentLink(uri);

abstract class AppLink {
  const AppLink(this.uri);

  final Uri uri;

  Future<void> navigate(BuildContext context);
}

class WalletConnectLink extends AppLink {
  const WalletConnectLink(super.uri);

  @override
  Future<void> navigate(BuildContext context) async {
    if (!isWalletConnectCompatibleChain(getIt.get<AppStore>().wallet!.type)) {
      await showPopUp<void>(
        context: context,
        builder: (context) => AlertWithOneAction(
          alertTitle: "WalletConnect",
          alertContent:
              S.of(context).switchToWCCompatibleWallet(walletConnectCompatibleChainsLabel()),
          buttonText: "OK",
          buttonAction: Navigator.of(context).pop,
        ),
      );
      return;
    }

    await Navigator.of(context).pushNamed(Routes.walletConnectConnectionsListing, arguments: uri);
  }
}

class QuickActionLink extends AppLink {
  const QuickActionLink(super.uri);

  @override
  Future<void> navigate(BuildContext context) async {
    final page = switch (uri.host) {
      "send" => getIt.get<NewSendPage>(param1: SendPageParams()),
      "receive" => getIt.get<NewReceivePage>(param1: false),
      _ => null,
    };
    if (page == null) {
      return;
    }

    Navigator.of(context).popUntil(ModalRoute.withName(Routes.dashboard));
    _openSheet(context, page);
  }
}

class NanoGptLink extends AppLink {
  const NanoGptLink(super.uri);

  @override
  Future<void> navigate(BuildContext context) async {
    switch (uri.authority) {
      case "send":
        if (_forwardToSendPage(uri)) {
          return;
        }
        _openSheet(
          context,
          getIt.get<NewSendPage>(
            param1: SendPageParams(initialPaymentRequest: PaymentRequest.fromUri(uri)),
          ),
        );
      case "exchange":
        _thank(context);
        _openSheet(context, getIt.get<NewSwapPage>(param1: PaymentRequest.fromUri(uri)));
      case "buy":
        _thank(context);
        _openBuySheet(
          context,
          getIt.get<NewBuySellAmountPage>(param1: NewBuySellParams(mode: BuySellPageMode.buy)),
        );
      default:
        await PaymentLink(uri).navigate(context);
    }
  }

  void _thank(BuildContext context) => unawaited(
        Fluttertoast.showToast(
          msg: S.of(context).nano_gpt_thanks_message,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 14,
        ).catchError((_) => false),
      );
}

class NodeLink extends AppLink {
  const NodeLink(super.uri);

  @override
  Future<void> navigate(BuildContext context) async {
    if (OpenCryptoPayService.isOpenCryptoPayQR(uri.toString())) {
      return PaymentLink(uri).navigate(context);
    }

    await Navigator.of(context).pushNamed(
      Routes.newNode,
      arguments: {"editingNode": Node.fromUri(uri, getIt.get<AppStore>().wallet!.type)},
    );
  }
}

class PaymentLink extends AppLink {
  const PaymentLink(super.uri);

  static Stream<Uri> get incoming => _incomingPaymentLinks.stream;

  @override
  Future<void> navigate(BuildContext context) async {
    if (_forwardToSendPage(uri)) {
      return;
    }

    _openSheet(context, getIt.get<NewSendPage>(param1: _sendPageParams));
  }

  SendPageParams get _sendPageParams {
    if (SendViewModelBase.isNonZeroAmountLightningInvoice(uri.toString())) {
      return _lightningParams(getBolt11Amount(uri.toString())?.toString() ?? "0");
    }
    if (SendViewModelBase.isLnurlInvoice(uri.toString())) {
      return _lightningParams("");
    }

    return SendPageParams(initialRawInput: uri.toString());
  }

  SendPageParams _lightningParams(String amount) => SendPageParams(
        initialPaymentRequest:
            PaymentRequest(stripLightningScheme(uri.toString()), amount, "", "", ""),
        unspentCoinType: UnspentCoinType.lightning,
      );
}

final _incomingPaymentLinks = StreamController<Uri>.broadcast();

bool _forwardToSendPage(Uri uri) {
  // if there's a send page already open, we apply the payment link on the send page instead of opening a second one
  if (!_incomingPaymentLinks.hasListener) {
    return false;
  }

  _incomingPaymentLinks.add(uri);
  return true;
}

void _openSheet(BuildContext context, Widget page) =>
    CupertinoScaffold.showCupertinoModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.black.withAlpha(85),
      builder: (context) => Material(child: ModalNavigator(rootPage: page, parentContext: context)),
    );

void _openBuySheet(BuildContext context, Widget page) => showModalBottomSheet<void>(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) => ModalNavigator(rootPage: page, parentContext: context),
    );
