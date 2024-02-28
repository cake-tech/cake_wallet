import 'package:cake_wallet/entities/qr_view_data.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/present_receive_option_picker.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/qr_code_theme.dart';
import 'package:cake_wallet/utils/brightness_util.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:cake_wallet/view_model/lightning_view_model.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_lightning/lightning_receive_page_option.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class LightningReceiveOnchainPage extends BasePage {
  LightningReceiveOnchainPage(
      {required this.addressListViewModel,
      required this.receiveOptionViewModel,
      required this.lightningViewModel})
      : _amountController = TextEditingController(),
        _formKey = GlobalKey<FormState>() {
    _amountController.addListener(() {
      if (_formKey.currentState!.validate()) {
        addressListViewModel.changeAmount(_amountController.text);
      }
    });
  }

  final WalletAddressListViewModel addressListViewModel;
  final ReceiveOptionViewModel receiveOptionViewModel;
  final LightningViewModel lightningViewModel;
  final TextEditingController _amountController;
  final GlobalKey<FormState> _formKey;

  bool effectsInstalled = false;

  @override
  String get title => S.current.receive;

  @override
  bool get gradientBackground => true;

  @override
  bool get resizeToAvoidBottomInset => true;

  @override
  Widget middle(BuildContext context) => PresentReceiveOptionPicker(
      color: titleColor(context), receiveOptionViewModel: receiveOptionViewModel);

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => GradientBackground(scaffold: scaffold);

  @override
  Widget body(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _setReactions(context));
    final copyImage = Image.asset('assets/images/copy_address.png',
        color: Theme.of(context).extension<QRCodeTheme>()!.qrWidgetCopyButtonColor);
    String heroTag = "lightning_receive";
    return Center(
      child: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FutureBuilder(
              future: lightningViewModel.receiveOnchain(),
              builder: ((context, snapshot) {
                if (snapshot.data == null) {
                  return CircularProgressIndicator();
                }
                String data = (snapshot.data as List<String>)[0];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        S.of(context).qr_fullscreen,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).extension<DashboardPageTheme>()!.textColor),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Spacer(flex: 3),
                        Observer(
                          builder: (_) => Flexible(
                            flex: 5,
                            child: GestureDetector(
                              onTap: () {
                                BrightnessUtil.changeBrightnessForFunction(
                                  () async {
                                    await Navigator.pushNamed(context, Routes.fullscreenQR,
                                        arguments: QrViewData(
                                          data: data,
                                          heroTag: heroTag,
                                        ));
                                  },
                                );
                              },
                              child: Hero(
                                tag: Key(heroTag),
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio: 1.0,
                                    child: Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 3,
                                          color: Theme.of(context)
                                              .extension<DashboardPageTheme>()!
                                              .textColor,
                                        ),
                                      ),
                                      child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              width: 3,
                                              color: Colors.white,
                                            ),
                                          ),
                                          child: QrImage(data: data)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Spacer(flex: 3)
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 20, bottom: 8, left: 24, right: 24),
                      child: Builder(
                        builder: (context) => Observer(
                          builder: (context) => GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: data));
                              showBar<void>(context, S.of(context).copied_to_clipboard);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    addressListViewModel.address.address,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .extension<DashboardPageTheme>()!
                                            .textColor),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: copyImage,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                );
              }),
            ),
            Container(
              padding: const EdgeInsets.only(top: 24, bottom: 24, right: 6),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                color: Color.fromARGB(94, 255, 221, 44),
                border: Border.all(
                  color: Color.fromARGB(178, 223, 214, 0),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    margin: EdgeInsets.only(left: 12, bottom: 48, right: 12),
                    child: Image.asset("assets/images/warning.png"),
                  ),
                  FutureBuilder(
                      future: lightningViewModel.receiveOnchain(),
                      builder: (context, snapshot) {
                        if (snapshot.data == null) {
                          return CircularProgressIndicator();
                        }
                        String min = (snapshot.data as List<String>)[1];
                        String max = (snapshot.data as List<String>)[2];
                        String fee = (snapshot.data as List<String>)[3];
                        min = satsToLightningString(double.parse(min));
                        max = satsToLightningString(double.parse(max));
                        fee = satsToLightningString(double.parse(fee));
                        return Expanded(
                          child: Text(
                            S.of(context).lightning_receive_limits(min, max, fee),
                            maxLines: 10,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                            ),
                          ),
                        );
                      }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setReactions(BuildContext context) {
    if (effectsInstalled) {
      return;
    }

    reaction((_) => receiveOptionViewModel.selectedReceiveOption, (ReceivePageOption option) async {
      switch (option) {
        case LightningReceivePageOption.lightningInvoice:
          Navigator.popAndPushNamed(
            context,
            Routes.lightningInvoice,
            arguments: [LightningReceivePageOption.lightningInvoice],
          );
          break;
        case LightningReceivePageOption.lightningOnchain:
          break;
        default:
          break;
      }
    });

    effectsInstalled = true;
  }
}
