import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/floating_icon_button.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/permission_handler.dart';
import 'package:cw_core/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:permission_handler_platform_interface/permission_handler_platform_interface.dart";

class NewSendAddressInput extends StatefulWidget {
  const NewSendAddressInput({
    super.key,
    required this.addressController,
    this.onURIScanned,
    this.onPushPasteButton,
    required this.selectedCurrency,
    this.onSelectedContact,
    this.onPushAddressBookButton,
    required this.onEditingComplete,
    this.bottomPadding = false,
    this.validator,
    this.focusNode, this.displayName,
  });

  final TextEditingController addressController;
  final Function(Uri)? onURIScanned;
  final Function(BuildContext)? onPushPasteButton;
  final Function(BuildContext)? onPushAddressBookButton;
  final Function(ContactBase)? onSelectedContact;
  final String? displayName;
  final Currency selectedCurrency;
  final VoidCallback onEditingComplete;
  final bool bottomPadding;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;

  @override
  State<NewSendAddressInput> createState() => _NewSendAddressInputState();
}

class _NewSendAddressInputState extends State<NewSendAddressInput> {
  FocusNode? node;
  GlobalKey<FormFieldState<String>> formFieldKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    node = widget.focusNode ?? FocusNode();
    node!.addListener(_onFocusChange);
    widget.addressController.addListener(()=>formFieldKey.currentState?.didChange(widget.addressController.text));
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.bottomPadding
          ? EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            )
          : EdgeInsets.zero,
      child: FormField<String>(
        key: formFieldKey,
        validator: widget.validator,
        builder: (state)=>Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        TextField(
                          focusNode: widget.focusNode,
                          onSubmitted: (val)=> FocusScope.of(context).unfocus(),
                          onChanged: state.didChange,
                          onEditingComplete: (){widget.onEditingComplete();},
                          onTapOutside: (_) {
                            widget.onEditingComplete();
                          },
                          controller: widget.addressController,
                          decoration: InputDecoration(
                            hintText: S.of(context).search_or_enter,
                            errorMaxLines: 3,
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                                duration: Duration(milliseconds: 150),
                                opacity: (widget.focusNode == null || widget.focusNode!.hasFocus || widget.addressController.text.isEmpty) ? 0 : 1,
                                child: SendAddressOverlay(
                                  address: widget.addressController.text,
                                  displayName: widget.displayName,
                                )
                              ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      SizedBox.shrink(),
                      FloatingIconButton(
                          iconPath: "assets/new-ui/paste.svg",
                          onPressed: () async {
                            _pasteAddress(context);
                          }),
                      FloatingIconButton(
                          iconPath: "assets/new-ui/scan.svg",
                          onPressed: () {
                            _presentQRScanner(context);
                          }),
                      FloatingIconButton(
                          iconPath: "assets/new-ui/contacts_outlined.svg",
                          onPressed: () {
                            _presetAddressBookPicker(context);
                          }),
                      SizedBox.shrink()
                    ],
                  )
                ],
              ),
            ),
            if(state.hasError)
              Padding(padding: EdgeInsets.only(top:6,left: 8),child: Text(state.errorText!, style: TextStyle(fontSize:12,color: Theme.of(context).colorScheme.error),),)
          ],
        ),
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
      widget.addressController.text = uri.path;
      widget.onURIScanned?.call(uri);
    } catch (_) {
      widget.addressController.text = code;
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
          widget.addressController.text = uri.path;
          widget.onURIScanned?.call(uri);
          return;
        } catch (_) {
          widget.addressController.text = address;
        }
      } else {
        widget.addressController.text = address;
      }
    }

    widget.onPushPasteButton?.call(context);
  }

  Future<void> _presetAddressBookPicker(BuildContext context) async {
    final contact = await Navigator.of(context)
        .pushNamed(Routes.pickerAddressBook, arguments: [widget.selectedCurrency, false]);

    if (contact is ContactBase) {
      widget.addressController.text = contact.address;
      widget.onPushAddressBookButton?.call(context);
      widget.onSelectedContact?.call(contact);
    }
  }
}

class SendAddressOverlay extends StatelessWidget {
  const SendAddressOverlay({super.key, required this.address, this.displayName});

  final String address;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final primaryTextStyle = TextStyle(fontSize: 16.5);
    final secondaryTextStyle =
        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant);

    final showDisplayName =
        displayName != null && displayName!.isNotEmpty && displayName != address;

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDisplayName)
              Text(
                displayName!,maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: primaryTextStyle,
              ),
            Text(
              address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: showDisplayName ? secondaryTextStyle : primaryTextStyle,
            )
          ],
        ),
      ),
    );
  }
}
