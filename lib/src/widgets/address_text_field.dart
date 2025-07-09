import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/permission_handler.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cw_core/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

enum AddressTextFieldOption { paste, qrCode, addressBook, walletAddresses }

class AddressTextField<T extends Currency> extends StatelessWidget {
  AddressTextField({
    required this.controller,
    this.isActive = true,
    this.placeholder,
    this.options = const [AddressTextFieldOption.qrCode, AddressTextFieldOption.addressBook],
    this.onURIScanned,
    this.focusNode,
    this.buttonColor,
    this.iconColor,
    this.textStyle,
    this.hintStyle,
    this.validator,
    this.onPushPasteButton,
    this.onPushAddressBookButton,
    this.onPushAddressPickerButton,
    this.onSelectedContact,
    this.selectedCurrency,
    this.addressKey,
    this.fillColor,
    this.hasUnderlineBorder = false,
    this.borderWidth = 1.0,
    this.contentPadding,
  });

  static const prefixIconWidth = 34.0;
  static const prefixIconHeight = 34.0;
  static const spaceBetweenPrefixIcons = 10.0;

  final TextEditingController? controller;
  final bool isActive;
  final String? placeholder;
  final Function(Uri)? onURIScanned;
  final List<AddressTextFieldOption> options;
  final FormFieldValidator<String>? validator;

  final Color? buttonColor;
  final Color? fillColor;
  final Color? iconColor;
  final double borderWidth;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final bool hasUnderlineBorder;
  final EdgeInsetsGeometry? contentPadding;
  final FocusNode? focusNode;
  final T? selectedCurrency;
  final Key? addressKey;

  final Function(BuildContext context)? onPushPasteButton;
  final Function(BuildContext context)? onPushAddressBookButton;
  final Function(BuildContext context)? onPushAddressPickerButton;
  final Function(ContactBase contact)? onSelectedContact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        BaseTextFormField(
          contentPadding: contentPadding,
          borderWidth: borderWidth,
          hasUnderlineBorder: hasUnderlineBorder,
          key: addressKey,
          enableIMEPersonalizedLearning: false,
          keyboardType: TextInputType.visiblePassword,
          onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
          enabled: isActive,
          controller: controller,
          focusNode: focusNode,
          textStyle: textStyle ??
              Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          fillColor: fillColor ?? Theme.of(context).colorScheme.surfaceContainer,
          suffixIcon: SizedBox(
            width: prefixIconWidth * options.length + (spaceBetweenPrefixIcons * options.length),
          ),
          placeholderTextStyle: hintStyle ??
              Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          hintText: placeholder ?? S.current.widgets_address,
          validator: validator,
        ),
        Positioned(
          top: 8,
          right: 6,
          child: SizedBox(
            width: (prefixIconWidth * options.length) + (spaceBetweenPrefixIcons * options.length),
            child: Row(
              mainAxisAlignment: responsiveLayoutUtil.shouldRenderMobileUI
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.end,
              children: [
                if (this.options.contains(AddressTextFieldOption.paste)) ...[
                  SizedBox(width: 5),
                  Container(
                    width: prefixIconWidth,
                    height: prefixIconHeight,
                    padding: EdgeInsets.only(top: 0),
                    child: Semantics(
                      label: S.of(context).paste,
                      child: InkWell(
                        onTap: () async => _pasteAddress(context),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                          ),
                          child: Image.asset(
                            'assets/images/paste_ios.png',
                            color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (this.options.contains(AddressTextFieldOption.qrCode) &&
                    DeviceInfo.instance.isMobile) ...[
                  SizedBox(width: 5),
                  Container(
                    width: prefixIconWidth,
                    height: prefixIconHeight,
                    padding: EdgeInsets.only(top: 0),
                    child: Semantics(
                      label: S.of(context).scan_qr_code,
                      child: InkWell(
                        onTap: () async => _presentQRScanner(context),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.all(
                              Radius.circular(6),
                            ),
                          ),
                          child: Image.asset(
                            'assets/images/qr_code_icon.png',
                            color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (this.options.contains(AddressTextFieldOption.addressBook)) ...[
                  SizedBox(width: 5),
                  Container(
                    width: prefixIconWidth,
                    height: prefixIconHeight,
                    padding: EdgeInsets.only(top: 0),
                    child: Semantics(
                      label: S.of(context).address_book,
                      child: InkWell(
                        onTap: () async => _presetAddressBookPicker(context),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.all(
                              Radius.circular(6),
                            ),
                          ),
                          child: Image.asset(
                            'assets/images/open_book.png',
                            color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (this.options.contains(AddressTextFieldOption.walletAddresses)) ...[
                  SizedBox(width: 5),
                  Container(
                    width: prefixIconWidth,
                    height: prefixIconHeight,
                    padding: EdgeInsets.only(top: 0),
                    child: Semantics(
                      label: S.of(context).address_book,
                      child: InkWell(
                        onTap: () async => _presetWalletAddressPicker(context),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: buttonColor ?? Theme.of(context).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                          ),
                          child: Image.asset(
                            'assets/images/open_book.png',
                            color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ],
            ),
          ),
        )
      ],
    );
  }

  Future<void> _presentQRScanner(BuildContext context) async {
    bool isCameraPermissionGranted =
        await PermissionHandler.checkPermission(Permission.camera, context);
    if (!isCameraPermissionGranted) return;
    final code = await presentQRScanner(context);
    if (code == null) return;
    if (code.isEmpty) return;

    try {
      final uri = Uri.parse(code);
      controller?.text = uri.path;
      onURIScanned?.call(uri);
    } catch (_) {
      controller?.text = code;
    }
  }

  Future<void> _presetAddressBookPicker(BuildContext context) async {
    final contact = await Navigator.of(context)
        .pushNamed(Routes.pickerAddressBook, arguments: selectedCurrency);

    if (contact is ContactBase) {
      controller?.text = contact.address;
      onPushAddressBookButton?.call(context);
      onSelectedContact?.call(contact);
    }
  }

  Future<void> _presetWalletAddressPicker(BuildContext context) async {
    final address = await Navigator.of(context).pushNamed(Routes.pickerWalletAddress);

    if (address is String) {
      controller?.text = address;
      onPushAddressPickerButton?.call(context);
    }
  }

  Future<void> _pasteAddress(BuildContext context) async {
    final clipboard = await Clipboard.getData('text/plain');
    final address = clipboard?.text ?? '';

    if (address.isNotEmpty) {
      // if it has query parameters then it's a valid uri
      // added because Uri.parse(address) can parse a normal address string and would still be valid
      if (address.contains("=")) {
        try {
          final uri = Uri.parse(address);
          controller?.text = uri.path;
          onURIScanned?.call(uri);
        } catch (_) {
          controller?.text = address;
        }
      } else {
        controller?.text = address;
      }
    }

    onPushPasteButton?.call(context);
  }
}
