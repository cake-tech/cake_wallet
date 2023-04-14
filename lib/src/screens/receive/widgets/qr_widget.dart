import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:device_display_brightness/device_display_brightness.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';

class QRWidget extends StatelessWidget {
  QRWidget(
      {required this.addressListViewModel,
      required this.isLight,
      this.qrVersion,
      this.isAmountFieldShow = false,
      this.amountTextFieldFocusNode})
      : amountController = TextEditingController(),
        _formKey = GlobalKey<FormState>() {
    amountController.addListener(() => addressListViewModel?.amount =
        _formKey.currentState!.validate() ? amountController.text : '');
  }

  final WalletAddressListViewModel addressListViewModel;
  final bool isAmountFieldShow;
  final TextEditingController amountController;
  final FocusNode? amountTextFieldFocusNode;
  final GlobalKey<FormState> _formKey;
  final bool isLight;
  final int? qrVersion;

  @override
  Widget build(BuildContext context) {
    final copyImage = Image.asset('assets/images/copy_address.png',
        color: Theme.of(context).textTheme.subtitle1!.decorationColor!);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                S.of(context).qr_fullscreen,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).accentTextTheme.headline2!.backgroundColor!),
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
                        changeBrightnessForRoute(() async {
                          await Navigator.pushNamed(
                            context,
                            Routes.fullscreenQR,
                            arguments: {
                              'qrData': addressListViewModel.uri.toString(),
                            },
                          );
                        });
                      },
                      child: Hero(
                        tag: Key(addressListViewModel.uri.toString()),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 3,
                                  color: Theme.of(context).accentTextTheme.headline2!.backgroundColor!,
                                ),
                              ),
                              child: QrImage(data: addressListViewModel.uri.toString()),
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
          ],
        ),
        if (isAmountFieldShow)
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: BaseTextFormField(
                      focusNode: amountTextFieldFocusNode,
                      controller: amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.deny(RegExp('[\\-|\\ ]'))],
                      textAlign: TextAlign.center,
                      hintText: S.of(context).receive_amount,
                      textColor: Theme.of(context).accentTextTheme!.headline2!.backgroundColor!,
                      borderColor: Theme.of(context).textTheme!.headline5!.decorationColor!,
                      validator: AmountValidator(
                          currency: walletTypeToCryptoCurrency(addressListViewModel!.type),
                          isAutovalidate: true),
                      // FIX-ME: Check does it equal to autovalidate: true,
                      autovalidateMode: AutovalidateMode.always,
                      placeholderTextStyle: TextStyle(
                        color: Theme.of(context).hoverColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Builder(
              builder: (context) => Observer(
                builder: (context) => GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: addressListViewModel!.address.address));
                    showBar<void>(context, S.of(context).copied_to_clipboard);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          addressListViewModel!.address.address,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color:
                                  Theme.of(context).accentTextTheme!.headline2!.backgroundColor!),
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
  }

  Future<void> changeBrightnessForRoute(Future<void> Function() navigation) async {
    // if not mobile, just navigate
    if (!DeviceInfo.instance.isMobile) {
      navigation();
      return;
    }

    // Get the current brightness:
    final brightness = await DeviceDisplayBrightness.getBrightness();

    // ignore: unawaited_futures
    DeviceDisplayBrightness.setBrightness(1.0);

    await navigation();

    // ignore: unawaited_futures
    DeviceDisplayBrightness.setBrightness(brightness);
  }
}
