import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/entities/contact_base.dart';

enum AddressTextFieldOption { paste, qrCode, addressBook }

class AddressTextField extends StatelessWidget {
  AddressTextField(
      {@required this.controller,
      this.isActive = true,
      this.placeholder,
      this.options = const [
        AddressTextFieldOption.qrCode,
        AddressTextFieldOption.addressBook
      ],
      this.onURIScanned,
      this.focusNode,
      this.isBorderExist = true,
      this.buttonColor,
      this.borderColor,
      this.iconColor,
      this.textStyle,
      this.hintStyle,
      this.validator,
      this.onPushPasteButton});

  static const prefixIconWidth = 34.0;
  static const prefixIconHeight = 34.0;
  static const spaceBetweenPrefixIcons = 10.0;

  final TextEditingController controller;
  final bool isActive;
  final String placeholder;
  final Function(Uri) onURIScanned;
  final List<AddressTextFieldOption> options;
  final FormFieldValidator<String> validator;
  final bool isBorderExist;
  final Color buttonColor;
  final Color borderColor;
  final Color iconColor;
  final TextStyle textStyle;
  final TextStyle hintStyle;
  final FocusNode focusNode;
  final Function(BuildContext context) onPushPasteButton;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        TextFormField(
          onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
          enabled: isActive,
          controller: controller,
          focusNode: focusNode,
          style: textStyle ??
              TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).primaryTextTheme.title.color),
          decoration: InputDecoration(
            suffixIcon: SizedBox(
              width: prefixIconWidth * options.length +
                  (spaceBetweenPrefixIcons * options.length),
            ),
            hintStyle: hintStyle ??
                TextStyle(fontSize: 16, color: Theme.of(context).hintColor),
            hintText: placeholder ?? S.current.widgets_address,
            focusedBorder: isBorderExist
                ? UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: borderColor ?? Theme.of(context).dividerColor,
                        width: 1.0))
                : InputBorder.none,
            disabledBorder: isBorderExist
                ? UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: borderColor ?? Theme.of(context).dividerColor,
                        width: 1.0))
                : InputBorder.none,
            enabledBorder: isBorderExist
                ? UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: borderColor ?? Theme.of(context).dividerColor,
                        width: 1.0))
                : InputBorder.none,
          ),
          validator: validator,
        ),
        Positioned(
            top: 2,
            right: 0,
            child: SizedBox(
              width: prefixIconWidth * options.length +
                  (spaceBetweenPrefixIcons * options.length),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 5),
                  if (this.options.contains(AddressTextFieldOption.paste)) ...[
                    Container(
                        width: prefixIconWidth,
                        height: prefixIconHeight,
                        padding: EdgeInsets.only(top: 0),
                        child: InkWell(
                          onTap: () async => _pasteAddress(context),
                          child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: buttonColor ??
                                      Theme.of(context)
                                          .accentTextTheme
                                          .title
                                          .color,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(6))),
                              child: Image.asset(
                                'assets/images/paste_ios.png',
                                color: iconColor ??
                                    Theme.of(context)
                                        .primaryTextTheme
                                        .display1
                                        .decorationColor,
                              )),
                        )),
                  ],
                  if (this.options.contains(AddressTextFieldOption.qrCode)) ...[
                    Container(
                        width: prefixIconWidth,
                        height: prefixIconHeight,
                        padding: EdgeInsets.only(top: 0),
                        child: InkWell(
                          onTap: () async => _presentQRScanner(context),
                          child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: buttonColor ??
                                      Theme.of(context)
                                          .accentTextTheme
                                          .title
                                          .color,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(6))),
                              child: Image.asset(
                                'assets/images/qr_code_icon.png',
                                color: iconColor ??
                                    Theme.of(context)
                                        .primaryTextTheme
                                        .display1
                                        .decorationColor,
                              )),
                        ))
                  ],
                  if (this
                      .options
                      .contains(AddressTextFieldOption.addressBook)) ...[
                    Container(
                        width: prefixIconWidth,
                        height: prefixIconHeight,
                        padding: EdgeInsets.only(top: 0),
                        child: InkWell(
                          onTap: () async => _presetAddressBookPicker(context),
                          child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: buttonColor ??
                                      Theme.of(context)
                                          .accentTextTheme
                                          .title
                                          .color,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(6))),
                              child: Image.asset(
                                'assets/images/open_book.png',
                                color: iconColor ??
                                    Theme.of(context)
                                        .primaryTextTheme
                                        .display1
                                        .decorationColor,
                              )),
                        ))
                  ]
                ],
              ),
            ))
      ],
    );
  }

  Future<void> _presentQRScanner(BuildContext context) async {
    try {
      final code = await presentQRScanner();
      final uri = Uri.parse(code);
      var address = '';

      if (uri == null) {
        controller.text = code;
        return;
      }

      address = uri.path;
      controller.text = address;

      if (onURIScanned != null) {
        onURIScanned(uri);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _presetAddressBookPicker(BuildContext context) async {
    final contact = await Navigator.of(context, rootNavigator: true)
        .pushNamed(Routes.pickerAddressBook);

    if (contact is ContactBase && contact.address != null) {
      controller.text = contact.address;
    }
  }

  Future<void> _pasteAddress(BuildContext context) async {
    String address;

    await Clipboard.getData('text/plain').then((value) => address = value?.text);

    if (address?.isNotEmpty ?? false) {
      controller.text = address;
    }

    onPushPasteButton?.call(context);
  }
}
