import "package:cake_wallet/core/wallet_name_validator.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/restore_wallet/wallet_restore_cubit.dart";
import "package:cake_wallet/src/widgets/address_text_field.dart";
import "package:cake_wallet/src/widgets/base_text_form_field.dart";
import "package:cake_wallet/src/widgets/blockchain_height_widget.dart";
import "package:cake_wallet/view_model/restore/restore_wallet.dart";
import "package:cw_core/generate_name.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class WalletRestoreFromKeysForm extends StatefulWidget {
  const WalletRestoreFromKeysForm({
    required this.walletRestoreCubit,
    required this.onPrivateKeyChange,
    required this.onViewKeyEntered,
    required this.displayPrivateKeyField,
    required this.onHeightOrDateEntered,
    required this.displayWalletPassword,
    required this.onRepeatedPasswordChange,
    super.key,
    this.restoredWallet,
    this.onPasswordChange,
  });

  final void Function(bool) onHeightOrDateEntered;
  final WalletRestoreCubit walletRestoreCubit;
  final void Function(String)? onPrivateKeyChange;
  final void Function(bool)? onViewKeyEntered;
  final bool displayPrivateKeyField;
  final bool displayWalletPassword;
  final RestoredWallet? restoredWallet;
  final void Function(String)? onPasswordChange;
  final void Function(String)? onRepeatedPasswordChange;

  @override
  WalletRestoreFromKeysFormState createState() => WalletRestoreFromKeysFormState();
}

class WalletRestoreFromKeysFormState extends State<WalletRestoreFromKeysForm> {
  final formKey = GlobalKey<FormState>();
  final blockchainHeightKey = GlobalKey<BlockchainHeightState>();

  late final TextEditingController nameTextEditingController;
  late final TextEditingController addressController;
  late final TextEditingController viewKeyController;
  late final TextEditingController spendKeyController;
  late final TextEditingController scanSecretController;
  late final TextEditingController spendPubkeyController;
  late final TextEditingController privateKeyController;
  TextEditingController? _passwordController;
  TextEditingController? _repeatedPasswordController;

  @override
  void initState() {
    super.initState();
    final restoredWallet = widget.restoredWallet;
    nameTextEditingController = TextEditingController(text: restoredWallet?.name);
    addressController = TextEditingController(text: restoredWallet?.address);
    viewKeyController = TextEditingController(text: restoredWallet?.viewKey)
      ..addListener(_onViewKeyChanged);
    spendKeyController = TextEditingController(text: restoredWallet?.spendKey);
    scanSecretController = TextEditingController(text: restoredWallet?.scanSecret);
    spendPubkeyController = TextEditingController(text: restoredWallet?.spendPubkey);
    privateKeyController = TextEditingController(text: restoredWallet?.privateKey)
      ..addListener(_onPrivateKeyChanged);

    if (widget.displayWalletPassword) {
      _passwordController = TextEditingController()..addListener(_onPasswordChanged);
      _repeatedPasswordController = TextEditingController()
        ..addListener(_onRepeatedPasswordChanged);
    }

    final restoreHeight = restoredWallet?.height;
    if (restoreHeight != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          blockchainHeightKey.currentState?.restoreHeightController.text = restoreHeight.toString();
        }
      });
    }
  }

  @override
  void dispose() {
    viewKeyController
      ..removeListener(_onViewKeyChanged)
      ..dispose();
    privateKeyController
      ..removeListener(_onPrivateKeyChanged)
      ..dispose();
    _passwordController
      ?..removeListener(_onPasswordChanged)
      ..dispose();
    _repeatedPasswordController
      ?..removeListener(_onRepeatedPasswordChanged)
      ..dispose();
    nameTextEditingController.dispose();
    addressController.dispose();
    spendKeyController.dispose();
    scanSecretController.dispose();
    spendPubkeyController.dispose();
    super.dispose();
  }

  void _onViewKeyChanged() => widget.onViewKeyEntered?.call(viewKeyController.text.isNotEmpty);

  void _onPrivateKeyChanged() {
    if (privateKeyController.text.isNotEmpty) {
      widget.onHeightOrDateEntered(true);
    }
    widget.onPrivateKeyChange?.call(privateKeyController.text);
  }

  void _onPasswordChanged() => widget.onPasswordChange?.call(_passwordController!.text);

  void _onRepeatedPasswordChanged() =>
      widget.onRepeatedPasswordChange?.call(_repeatedPasswordController!.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 8),
              BaseTextFormField(
                key: const ValueKey("wallet_restore_from_keys_wallet_name_textfield_key"),
                controller: nameTextEditingController,
                hintText: S.of(context).wallet_name,
                validator: WalletNameValidator(),
                suffixIcon: IconButton(
                  key: const ValueKey("wallet_restore_from_keys_wallet_name_refresh_button_key"),
                  onPressed: _generateWalletName,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.0),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    width: 34,
                    height: 34,
                    child: Image.asset(
                      "assets/images/refresh_icon.png",
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (widget.displayWalletPassword) ...[
                Container(
                  key: const ValueKey("password"),
                  padding: const EdgeInsets.only(top: 20.0),
                  child: BaseTextFormField(
                    controller: _passwordController,
                    hintText: S.of(context).password,
                    obscureText: true,
                  ),
                ),
                Container(
                  key: const ValueKey("repeat_wallet_password"),
                  padding: const EdgeInsets.only(top: 20.0),
                  child: BaseTextFormField(
                    controller: _repeatedPasswordController,
                    hintText: S.of(context).repeat_wallet_password,
                    obscureText: true,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _buildKeyFields(),
            ],
          ),
        ),
      );

  Widget _buildKeyFields() {
    final cubit = widget.walletRestoreCubit;

    if (cubit.onlyViewKeyRestore) {
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
      final isNanoBased = cubit.type == WalletType.nano || cubit.type == WalletType.banano;
      return Column(
        children: [
          AddressTextField(
            addressKey: const ValueKey("wallet_restore_from_key_private_key_textfield_key"),
            controller: privateKeyController,
            placeholder: isNanoBased ? S.of(context).seed_hex_form : S.of(context).private_key,
            options: const [AddressTextFieldOption.paste],
            onPushPasteButton: (_) => _pastePrivateKey(),
          ),
          if (cubit.hasBlockchainHeightSelector) _buildBlockchainHeightWidget(cubit.type),
        ],
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
          padding: const EdgeInsets.only(top: 20.0),
          child: BaseTextFormField(
            controller: viewKeyController,
            hintText: S.of(context).restore_view_key_private,
            maxLines: null,
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 20.0),
          child: BaseTextFormField(
            controller: spendKeyController,
            hintText: S.of(context).restore_spend_key_private,
            maxLines: null,
          ),
        ),
        if (cubit.type == WalletType.litecoin)
          Container(
            padding: const EdgeInsets.only(top: 20.0),
            child: BaseTextFormField(
              controller: scanSecretController,
              hintText: "Scan secret",
              maxLines: null,
            ),
          ),
        Container(
          padding: const EdgeInsets.only(top: 20.0),
          child: BaseTextFormField(
            controller: spendPubkeyController,
            hintText: "Spend public key",
            maxLines: null,
          ),
        ),
        if (cubit.hasBlockchainHeightSelector) _buildBlockchainHeightWidget(cubit.type),
      ],
    );
  }

  Widget _buildBlockchainHeightWidget(WalletType type) => BlockchainHeightWidget(
        key: blockchainHeightKey,
        hasDatePicker: type != WalletType.haven,
        onHeightChange: (_) {},
        onHeightOrDateEntered: widget.onHeightOrDateEntered,
        walletType: type,
      );

  Future<void> _generateWalletName() async {
    final generatedName = await generateName();
    if (!mounted) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    nameTextEditingController
      ..text = generatedName
      ..selection = TextSelection.collapsed(offset: generatedName.length);
  }

  Future<void> _pastePrivateKey() async {
    final value = await Clipboard.getData(Clipboard.kTextPlain);
    final text = value?.text;
    if (!mounted || text == null || text.isEmpty) {
      return;
    }
    privateKeyController.text = text;
  }
}
