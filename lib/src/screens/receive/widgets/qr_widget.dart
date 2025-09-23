import 'package:cake_wallet/entities/qr_view_data.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/src/screens/receive/widgets/currency_input_field.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/utils/brightness_util.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:url_launcher/url_launcher.dart';

class QRWidget extends StatelessWidget {
  QRWidget({
    required this.addressListViewModel,
    required this.currentTheme,
    this.qrVersion,
    this.heroTag,
    required this.amountController,
    required this.formKey,
    this.amountTextFieldFocusNode,
  });

  final WalletAddressListViewModel addressListViewModel;
  final TextEditingController amountController;
  final FocusNode? amountTextFieldFocusNode;
  final GlobalKey<FormState> formKey;
  final MaterialThemeBase currentTheme;
  final int? qrVersion;
  final String? heroTag;

  PaymentURI get addressUri {
    return addressListViewModel.uri;
  }

  @override
  Widget build(BuildContext context) {
    final copyImage = Image.asset(
      'assets/images/copy_address.png',
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    // This magic number for wider screen sets the text input focus at center of the inputfield
    final _width =
        responsiveLayoutUtil.shouldRenderMobileUI ? MediaQuery.of(context).size.width : 500;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Column(
              children: [
                Row(
                  children: <Widget>[
                    Spacer(flex: 3),
                    Observer(
                      builder: (_) => Flexible(
                        flex: 9,
                        child: GestureDetector(
                          onTap: () {
                            BrightnessUtil.changeBrightnessForFunction(
                              () async {
                                await Navigator.pushNamed(
                                  context,
                                  Routes.fullscreenQR,
                                  arguments: QrViewData(
                                    embeddedImagePath: addressListViewModel.qrImage,
                                    data: addressUri.toString(),
                                    heroTag: heroTag,
                                  ),
                                );
                              },
                            );
                          },
                          child: Hero(
                            tag: Key(heroTag ?? addressUri.toString()),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide.none),
                                  borderRadius: BorderRadius.all(Radius.circular(5)),
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12.5),
                                      child: AspectRatio(
                                        aspectRatio: 1.0,
                                        child: QrImage(
                                          embeddedImagePath: addressListViewModel.qrImage,
                                          data: addressUri.toString(),
                                          size: 230,
                                        ),
                                      ),
                                    ),
                                    if (addressListViewModel.isPayjoinUnavailable &&
                                        !addressListViewModel.isSilentPayments &&
                                        !addressListViewModel.isCupcake) ...[
                                      GestureDetector(
                                        onTap: () => _onPayjoinInactivePressed(context),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 4,
                                                bottom: 4,
                                                right: 4,
                                              ),
                                              child: Image.asset(
                                                'assets/images/payjoin.png',
                                                width: 20,
                                              ),
                                            ),
                                            Text(
                                              S.of(context).payjoin_unavailable,
                                              style:
                                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 4,
                                                bottom: 4,
                                                left: 4,
                                              ),
                                              child: CircleAvatar(
                                                radius: 7,
                                                backgroundColor: Colors.black,
                                                child: Icon(
                                                  Icons.question_mark,
                                                  size: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (addressListViewModel.payjoinEndpoint.isNotEmpty &&
                                        !addressListViewModel.isSilentPayments) ...[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: 4,
                                              bottom: 4,
                                              right: 4,
                                            ),
                                            child: Image.asset(
                                              'assets/images/payjoin.png',
                                              width: 20,
                                            ),
                                          ),
                                          Text(
                                            S.of(context).payjoin_enabled,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ]
                                  ],
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
            Observer(
                builder: (_) => Row(
                      children: <Widget>[
                        Expanded(
                          child: Form(
                            key: formKey,
                            child: CurrencyAmountTextField(
                              hasUnderlineBorder: true,
                              borderWidth: 0.0,
                              selectedCurrency: _currencyName,
                              selectedCurrencyDecimals:
                                  addressListViewModel.selectedCurrency.decimals,
                              amountFocusNode: amountTextFieldFocusNode,
                              amountController: amountController,
                              padding: EdgeInsets.only(top: 20, left: _width / 4),
                              currentThemeType: currentTheme.type,
                              isAmountEditable: true,
                              tag: addressListViewModel.selectedCurrency.tag,
                              onTapPicker: () => _presentPicker(context),
                              isPickerEnable: true,
                            ),
                          ),
                        ),
                      ],
                    )),
            Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
            Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: Builder(
                builder: (context) => Observer(
                  builder: (context) => GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: addressUri.address));
                      showBar<void>(context, S.of(context).copied_to_clipboard);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: AddressFormatter.buildSegmentedAddress(
                            address: addressUri.address,
                            walletType: addressListViewModel.type,
                            textAlign: TextAlign.center,
                            evenTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
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
            ),
            Observer(
              builder: (_) => Offstage(
                offstage: addressListViewModel.payjoinEndpoint.isEmpty ||
                    addressListViewModel.isSilentPayments,
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: PrimaryImageButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: addressUri.toString()));
                      showBar<void>(context, S.of(context).copied_to_clipboard);
                    },
                    image: Image.asset(
                      'assets/images/payjoin.png',
                      width: 25,
                    ),
                    text: S.of(context).copy_payjoin_address,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    textColor: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _currencyName {
    if (addressListViewModel.selectedCurrency is CryptoCurrency) {
      return (addressListViewModel.selectedCurrency as CryptoCurrency).title.toUpperCase();
    }
    return addressListViewModel.selectedCurrency.name.toUpperCase();
  }

  void _presentPicker(BuildContext context) async {
    await showPopUp<void>(
      builder: (_) => CurrencyPicker(
        selectedAtIndex: addressListViewModel.selectedCurrencyIndex,
        items: addressListViewModel.currencies,
        hintText: S.of(context).search_currency,
        onItemSelected: addressListViewModel.selectCurrency,
      ),
      context: context,
    );
    // update amount if currency changed
    addressListViewModel.changeAmount(amountController.text);
  }

  void _onPayjoinInactivePressed(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => InfoBottomSheet(
        titleText: S.of(context).payjoin_unavailable_sheet_title,
        content: S.of(context).payjoin_unavailable_sheet_content,
        currentTheme: currentTheme,
        footerType: FooterType.doubleActionButton,
        doubleActionLeftButtonText: S.of(context).learn_more,
        onLeftActionButtonPressed: () => launchUrl(
            Uri.parse("https://docs.cakewallet.com/cryptos/bitcoin/#payjoin"),
            mode: LaunchMode.externalApplication),
        doubleActionRightButtonText: S.of(context).ok,
        onRightActionButtonPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
