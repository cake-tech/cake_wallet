import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/view_model/restore/restore_wallet.dart';
import 'package:cake_wallet/view_model/wallet_restore_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/blockchain_height_widget.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/core/wallet_name_validator.dart';
import 'package:cake_wallet/entities/generate_name.dart';
import 'package:flutter/services.dart';

class WalletRestoreFromKeysForm extends StatefulWidget {
  WalletRestoreFromKeysForm({
    required this.walletRestoreViewModel,
    required this.onPrivateKeyChange,
    required this.onViewKeyEntered,
    required this.displayPrivateKeyField,
    required this.onHeightOrDateEntered,
    required this.displayWalletPassword,
    required this.onRepeatedPasswordChange,
    this.restoredWallet,
    this.onPasswordChange,
    required this.currentTheme,
    Key? key,
  }) : super(key: key);

  final Function(bool) onHeightOrDateEntered;
  final WalletRestoreViewModel walletRestoreViewModel;
  final void Function(String)? onPrivateKeyChange;
  final void Function(bool)? onViewKeyEntered;
  final bool displayPrivateKeyField;
  final bool displayWalletPassword;
  final RestoredWallet? restoredWallet;
  final void Function(String)? onPasswordChange;
  final void Function(String)? onRepeatedPasswordChange;
  final MaterialThemeBase currentTheme;
  
  @override
  WalletRestoreFromKeysFormState createState() => WalletRestoreFromKeysFormState(
      displayWalletPassword: displayWalletPassword, restoredWallet: restoredWallet);
}

class WalletRestoreFromKeysFormState extends State<WalletRestoreFromKeysForm> {
  WalletRestoreFromKeysFormState(
      {required bool displayWalletPassword, RestoredWallet? restoredWallet})
      : formKey = GlobalKey<FormState>(),
        blockchainHeightKey = GlobalKey<BlockchainHeightState>(),
        nameController = TextEditingController(),
        addressController = restoredWallet != null
            ? TextEditingController(text: restoredWallet.address)
            : TextEditingController(),
        viewKeyController = restoredWallet != null
            ? TextEditingController(text: restoredWallet.viewKey)
            : TextEditingController(),
        spendKeyController = restoredWallet != null
            ? TextEditingController(text: restoredWallet.spendKey)
            : TextEditingController(),
        privateKeyController = restoredWallet != null
            ? TextEditingController(text: restoredWallet.privateKey)
            : TextEditingController(),
        nameTextEditingController = TextEditingController(),
        passwordTextEditingController = displayWalletPassword ? TextEditingController() : null,
        repeatedPasswordTextEditingController =
            displayWalletPassword ? TextEditingController() : null;

  final GlobalKey<FormState> formKey;
  final GlobalKey<BlockchainHeightState> blockchainHeightKey;
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController viewKeyController;
  final TextEditingController spendKeyController;
  final TextEditingController nameTextEditingController;
  final TextEditingController privateKeyController;
  final TextEditingController? passwordTextEditingController;
  final TextEditingController? repeatedPasswordTextEditingController;
  void Function()? passwordListener;
  void Function()? repeatedPasswordListener;

  @override
  void initState() {
    if (passwordTextEditingController != null) {
      passwordListener = () => widget.onPasswordChange?.call(passwordTextEditingController!.text);
      passwordTextEditingController?.addListener(passwordListener!);
    }

    if (repeatedPasswordTextEditingController != null) {
      repeatedPasswordListener =
          () => widget.onRepeatedPasswordChange?.call(repeatedPasswordTextEditingController!.text);
      repeatedPasswordTextEditingController?.addListener(repeatedPasswordListener!);
    }
    super.initState();

    privateKeyController.addListener(() {
      if (privateKeyController.text.isNotEmpty) {
        widget.onHeightOrDateEntered(true);
      }
      widget.onPrivateKeyChange?.call(privateKeyController.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.restoredWallet?.height != null) {
        blockchainHeightKey.currentState?.restoreHeightController.text =
            widget.restoredWallet!.height.toString();
      }
    });

    viewKeyController.addListener(() {
      widget.onViewKeyEntered?.call(viewKeyController.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    viewKeyController.dispose();
    privateKeyController.dispose();
    spendKeyController.dispose();
    passwordTextEditingController?.dispose();
    if (passwordListener != null) {
      passwordTextEditingController?.removeListener(passwordListener!);
    }

    if (repeatedPasswordListener != null) {
      repeatedPasswordTextEditingController?.removeListener(repeatedPasswordListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: formKey,
        child: Column(
          children: <Widget>[
            SizedBox(height: 8),
            BaseTextFormField(
              key: ValueKey('wallet_restore_from_keys_wallet_name_textfield_key'),
              controller: nameTextEditingController,
              hintText: S.of(context).wallet_name,
              validator: WalletNameValidator(),
              suffixIcon: IconButton(
                key: ValueKey('wallet_restore_from_keys_wallet_name_refresh_button_key'),
                onPressed: () async {
                  final rName = await generateName();
                  FocusManager.instance.primaryFocus?.unfocus();

                  setState(() {
                    nameTextEditingController.text = rName;
                    nameTextEditingController.selection = TextSelection.fromPosition(
                        TextPosition(offset: nameTextEditingController.text.length));
                  });
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.0),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  width: 34,
                  height: 34,
                  child: Image.asset(
                    'assets/images/refresh_icon.png',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (widget.displayWalletPassword) ...[
              Container(
                key: ValueKey('password'),
                padding: EdgeInsets.only(top: 20.0),
                child: BaseTextFormField(
                  controller: passwordTextEditingController,
                  hintText: S.of(context).password,
                  obscureText: true,
                ),
              ),
              Container(
                key: ValueKey('repeat_wallet_password'),
                padding: EdgeInsets.only(top: 20.0),
                child: BaseTextFormField(
                  controller: repeatedPasswordTextEditingController,
                  hintText: S.of(context).repeat_wallet_password,
                  obscureText: true,
                ),
              )
            ],
            Container(height: 20),
            _restoreFromKeysFormFields(),
          ],
        ),
      ),
    );
  }

  Widget _restoreFromKeysFormFields() {
    // Decred can only restore a view only wallet with an account pubkey. Other
    // fields are not used.
    if (widget.walletRestoreViewModel.onlyViewKeyRestore) {
      return Column(
        children: [
          BaseTextFormField(
            controller: viewKeyController,
            hintText: S.of(context).view_key_public,
            maxLines: null,
          ),
        ],
      );
    }

    if (widget.displayPrivateKeyField) {
      // the term "private key" isn't actually what we're accepting here, and it's confusing to
      // users of the nano community, what this form actually accepts (when importing for nano) is a nano seed in it's hex form, referred to in code as a "seed key"
      // so we should change the placeholder text to reflect this
      // supporting actual nano private keys is possible, but it's super niche in the nano community / they're not really used

      bool nanoBased = widget.walletRestoreViewModel.type == WalletType.nano ||
          widget.walletRestoreViewModel.type == WalletType.banano;
      return AddressTextField(
        addressKey: ValueKey('wallet_restore_from_key_private_key_textfield_key'),
        controller: privateKeyController,
        placeholder: nanoBased ? S.of(context).seed_hex_form : S.of(context).private_key,
        options: [AddressTextFieldOption.paste],
        onPushPasteButton: (_) {
          _pasteText();
        },
      );
    }

    return Column(
      children: [
        BaseTextFormField(
          controller: addressController,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          hintText: S.of(context).restore_address,
        ),
        Container(
          padding: EdgeInsets.only(top: 20.0),
          child: BaseTextFormField(
            controller: viewKeyController,
            hintText: S.of(context).restore_view_key_private,
            maxLines: null,
          ),
        ),
        Container(
          padding: EdgeInsets.only(top: 20.0),
          child: BaseTextFormField(
            controller: spendKeyController,
            hintText: S.of(context).restore_spend_key_private,
            maxLines: null,
          ),
        ),
        if (widget.walletRestoreViewModel.hasBlockchainHeightSelector)
          BlockchainHeightWidget(
            currentTheme: widget.currentTheme,
            key: blockchainHeightKey,
            hasDatePicker: widget.walletRestoreViewModel.type != WalletType.haven,
            onHeightChange: (_) => null,
            onHeightOrDateEntered: widget.onHeightOrDateEntered,
            walletType: widget.walletRestoreViewModel.type,
          ),
      ],
    );
  }

  Future<void> _pasteText() async {
    final value = await Clipboard.getData('text/plain');

    if (value?.text?.isNotEmpty ?? false) {
      privateKeyController.text = value!.text!;
    }
  }
}
