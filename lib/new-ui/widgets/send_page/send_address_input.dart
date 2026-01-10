import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/floating_icon_button.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/permission_handler.dart';
import 'package:cw_core/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:permission_handler_platform_interface/permission_handler_platform_interface.dart";

class NewSendAddressInput extends StatelessWidget {
  const NewSendAddressInput({super.key, required this.addressController, this.onURIScanned, this.onPushPasteButton, required this.selectedCurrency, this.onSelectedContact, this.onPushAddressBookButton});

  final TextEditingController addressController;
  final Function(Uri)? onURIScanned;
  final Function(BuildContext)? onPushPasteButton;
  final Function(BuildContext)? onPushAddressBookButton;
  final Function(ContactBase)? onSelectedContact;
  final Currency selectedCurrency;




  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16)
      ),
      child: Row(
        children: [
          Expanded(child: TextField(controller: addressController,decoration: InputDecoration(
            hintText: "Search or enter"
          ))),
          Row(
            spacing:12,children: [
            SizedBox.shrink(),
            FloatingIconButton(iconPath: "assets/new-ui/paste.svg", onPressed: () async {
             _pasteAddress(context);
            }),
            FloatingIconButton(iconPath: "assets/new-ui/scan.svg", onPressed: (){_presentQRScanner(context);}),
            FloatingIconButton(iconPath: "assets/new-ui/contacts_outlined.svg", onPressed: (){_presetAddressBookPicker(context);}),
            SizedBox.shrink()
          ],
          )

        ],
      ),
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
      addressController.text = uri.path;
      onURIScanned?.call(uri);
    } catch (_) {
      addressController.text = code;
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
          addressController.text = uri.path;
          onURIScanned?.call(uri);
        } catch (_) {
          addressController.text = address;
        }
      } else {
        addressController.text = address;
      }
    }

    onPushPasteButton?.call(context);
  }


  Future<void> _presetAddressBookPicker(BuildContext context) async {
    final contact = await Navigator.of(context)
        .pushNamed(Routes.pickerAddressBook, arguments: selectedCurrency);

    if (contact is ContactBase) {
      addressController.text = contact.address;
      onPushAddressBookButton?.call(context);
      onSelectedContact?.call(contact);
    }
  }
}