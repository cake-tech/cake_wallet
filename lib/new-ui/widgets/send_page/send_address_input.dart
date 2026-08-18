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
    this.focusNode,
    this.displayName,
    this.hintText,
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
  final String? hintText;

  @override
  State<NewSendAddressInput> createState() => _NewSendAddressInputState();
}

class _NewSendAddressInputState extends State<NewSendAddressInput> {
  FocusNode? node;
  GlobalKey<FormFieldState<String>> formFieldKey = GlobalKey<FormFieldState<String>>();

  // Guards against re-entrant normalization when we rewrite the controller
  // text from inside the listener (which would otherwise re-trigger the
  // listener with the stripped address and cause feedback loops).
  bool _isNormalizing = false;

  @override
  void initState() {
    super.initState();
    node = widget.focusNode ?? FocusNode();
    node!.addListener(_onFocusChange);
    widget.addressController.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    widget.addressController.removeListener(_onAddressChanged);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onAddressChanged() {
    if (_isNormalizing) return;
    final raw = widget.addressController.text;

    // Detect a BIP21 URI typed or system-pasted directly into the field.
    // The strict address validator would otherwise reject the full URI as
    // "not recognized", and the payjoin `pj=`/`amount=` params would never
    // reach the send view model. Normalize by collapsing the field to the
    // bare address and dispatching the original URI via [onURIScanned].
    if (_isBip21Uri(raw)) {
      _isNormalizing = true;
      try {
        final uri = Uri.parse(raw);
        final bare = uri.path;
        if (bare.isNotEmpty && bare != raw) {
          widget.addressController.text = bare;
          // Defer the callback so the controller/text-field rebuild settles
          // before downstream handlers mutate state based on it.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onURIScanned?.call(uri);
          });
        }
        formFieldKey.currentState?.didChange(bare);
      } finally {
        _isNormalizing = false;
      }
      return;
    }

    formFieldKey.currentState?.didChange(raw);
  }

  /// Returns true if [input] looks like a BIP21 payment URI such as
  /// `bitcoin:bc1q...?amount=0.001&pj=https://...`. A bare address never
  /// has both a scheme separator and a query string.
  bool _isBip21Uri(String input) {
    if (!input.contains(':') || !input.contains('?')) return false;
    try {
      final uri = Uri.parse(input);
      return uri.scheme.isNotEmpty &&
          uri.queryParameters.isNotEmpty &&
          uri.path.isNotEmpty;
    } catch (_) {
      return false;
    }
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
        initialValue: widget.addressController.text,
        validator: widget.validator,
        builder: (state) => Column(
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
                        MergeSemantics(
                          child: Semantics(
                            label: _fieldSemanticsLabel(context),
                            child: TextField(
                              focusNode: widget.focusNode,
                              autocorrect: false,
                              enableSuggestions: false,
                              onSubmitted: (val) => FocusScope.of(context).unfocus(),
                              onChanged: state.didChange,
                              onEditingComplete: () {
                                widget.onEditingComplete();
                              },
                              onTapOutside: (_) {
                                widget.onEditingComplete();
                              },
                              controller: widget.addressController,
                              decoration: InputDecoration(
                                hintText: widget.hintText ?? S.of(context).search_or_enter,
                                errorMaxLines: 3,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                                duration: Duration(milliseconds: 150),
                                opacity: (widget.focusNode == null ||
                                        widget.focusNode!.hasFocus ||
                                        widget.addressController.text.isEmpty)
                                    ? 0
                                    : 1,
                                // Purely visual copy of the field content; announcing it again
                                // would read the address twice.
                                child: ExcludeSemantics(
                                  child: SendAddressOverlay(
                                    address: widget.addressController.text,
                                    displayName: widget.displayName,
                                  ),
                                )),
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
            if (state.hasError)
              Padding(
                padding: EdgeInsets.only(top: 6, left: 8),
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label: "${S.of(context).address_or_alias}, ${state.errorText!}",
                  excludeSemantics: true,
                  child: Text(
                    state.errorText!,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  String _fieldSemanticsLabel(BuildContext context) {
    final label = S.of(context).address_or_alias;
    final displayName = widget.displayName;

    if (displayName == null ||
        displayName.isEmpty ||
        displayName == widget.addressController.text) {
      return label;
    }

    return "$label, $displayName";
  }

  Future<void> _presentQRScanner(BuildContext context) async {
    bool isCameraPermissionGranted =
        await PermissionHandler.checkPermission(Permission.camera, context);
    if (!isCameraPermissionGranted) return;
    final code = await presentQRScanner(context);
    if (code == null) return;
    if (code.isEmpty) return;

    if (_applyScannedOrPasted(code)) return;

    widget.onPushPasteButton?.call(context);
  }

  Future<void> _pasteAddress(BuildContext context) async {
    final clipboard = await Clipboard.getData('text/plain');
    final address = clipboard?.text ?? '';

    if (address.isEmpty) return;

    if (_applyScannedOrPasted(address)) return;

    widget.addressController.text = address;
    widget.onPushPasteButton?.call(context);
  }

  /// Normalizes a scanned/pasted string that turns out to be a BIP21 payment
  /// URI. Sets the visible field text to the bare address and dispatches the
  /// full URI through [onURIScanned] so the send view model receives the
  /// `amount=`/`pj=` parameters.
  ///
  /// Returns true if [input] was recognized as a BIP21 URI and handled.
  bool _applyScannedOrPasted(String input) {
    if (!_isBip21Uri(input)) return false;
    try {
      final uri = Uri.parse(input);
      // Bare on-chain address goes in the visible field; the full URI
      // (including `pj=`, `amount=`, ERC681 contract path, etc.) is delivered
      // via onURIScanned so the send view model can parse it.
      widget.addressController.text = uri.path;
      widget.onURIScanned?.call(uri);
      return true;
    } catch (_) {
      return false;
    }
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
                displayName!,
                maxLines: 1,
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
