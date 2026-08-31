import "package:cake_wallet/core/address_validator.dart";
import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/entities/solana_nft_asset_model.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/widgets/address_text_field.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/gradient_background.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/dashboard/nft_send_view_model.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/pending_transaction.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

class NFTSendPage extends StatefulWidget {
  const NFTSendPage({
    required this.nftSendViewModel,
    required this.authService,
    required this.arguments,
    super.key,
  });

  final NFTSendViewModel nftSendViewModel;
  final AuthService authService;
  final NFTSendPageArguments arguments;

  @override
  State<NFTSendPage> createState() => _NFTSendPageState();
}

class _NFTSendPageState extends State<NFTSendPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    addressController = TextEditingController();
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _NFTSendPage(
        nftSendViewModel: widget.nftSendViewModel,
        authService: widget.authService,
        asset: widget.arguments.asset,
        formKey: formKey,
        addressController: addressController,
      );
}

class _NFTSendPage extends BasePage {
  _NFTSendPage({
    required this.nftSendViewModel,
    required this.authService,
    required this.asset,
    required this.formKey,
    required this.addressController,
  });

  final NFTSendViewModel nftSendViewModel;
  final AuthService authService;
  final SolanaNFTAssetModel asset;
  final GlobalKey<FormState> formKey;
  final TextEditingController addressController;

  @override
  String get title => S.current.send;

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (context, scaffold) => GradientBackground(scaffold: scaffold);

  @override
  Widget body(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: MediaQuery.sizeOf(context).height / 3.5,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.outline),
                  color: colorScheme.surface,
                ),
                child: CakeImageWidget(imageUrl: asset.imageOriginalUrl),
              ),
              const SizedBox(height: 16),
              Text(
                (asset.name?.isNotEmpty ?? false) ? asset.name! : (asset.symbol ?? "---"),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.surfaceContainer,
                ),
                child: AddressTextField(
                  controller: addressController,
                  placeholder: S.of(context).recipient_address,
                  options: const [
                    AddressTextFieldOption.paste,
                    AddressTextFieldOption.qrCode,
                  ],
                  buttonColor: colorScheme.surfaceContainerHighest,
                  validator: AddressValidator(type: CryptoCurrency.sol).call,
                ),
              ),
              const SizedBox(height: 24),
              Observer(
                builder: (_) => LoadingPrimaryButton(
                  text: S.of(context).send,
                  color: colorScheme.primary,
                  textColor: colorScheme.onPrimary,
                  isLoading: nftSendViewModel.state is IsExecutingState,
                  onPressed: () => _onSendPressed(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSendPressed(BuildContext context) async {
    if (nftSendViewModel.state is IsExecutingState) {
      return;
    }

    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final destinationAddress = addressController.text.trim();

    await authService.authenticateAction(
      context,
      conditionToDetermineIfToUse2FA: nftSendViewModel.shouldRequireTOTP2FAFor(destinationAddress),
      onAuthSuccess: (isAuthenticatedSuccessfully) async {
        if (!isAuthenticatedSuccessfully || !context.mounted) {
          return;
        }

        await _createAndConfirm(context, destinationAddress);
      },
    );
  }

  Future<void> _createAndConfirm(BuildContext context, String destinationAddress) async {
    await nftSendViewModel.createTransaction(asset, destinationAddress);

    if (!context.mounted) {
      return;
    }

    final state = nftSendViewModel.state;

    if (state is FailureState) {
      await _showError(context, state.error);
      return;
    }

    final pendingTransaction = nftSendViewModel.pendingTransaction;

    if (pendingTransaction == null) {
      return;
    }

    final confirmed = await _confirm(context, destinationAddress, pendingTransaction);

    if (!context.mounted) {
      return;
    }

    if (!confirmed) {
      nftSendViewModel.reset();
      return;
    }

    await _commit(context);
  }

  Future<bool> _confirm(
    BuildContext context,
    String destinationAddress,
    PendingTransaction pendingTransaction,
  ) async {
    final additionalCost = pendingTransaction.additionalCost;

    var confirmed = false;

    await showPopUp<void>(
      context: context,
      builder: (dialogContext) => AlertWithTwoActions(
        alertTitle: S.of(context).confirm_sending,
        alertContent: "",
        alertContentTextWidget: _NFTSendConfirmation(
          name: asset.name,
          mint: asset.mint,
          destinationAddress: destinationAddress,
          fee: pendingTransaction.feeFormatted,
          accountCreationFee: additionalCost?.toStringWithSymbol(fractionalDigits: 8),
        ),
        leftButtonText: S.of(context).cancel,
        rightButtonText: S.of(context).send,
        actionLeftButton: () => Navigator.of(dialogContext).pop(),
        actionRightButton: () {
          confirmed = true;
          Navigator.of(dialogContext).pop();
        },
      ),
    );

    return confirmed;
  }

  Future<void> _commit(BuildContext context) async {
    await nftSendViewModel.commitTransaction();

    if (!context.mounted) {
      return;
    }

    final state = nftSendViewModel.state;
    if (state is FailureState) {
      await _showError(context, state.error);
      return;
    }

    await showPopUp<void>(
      context: context,
      builder: (dialogContext) => AlertWithOneAction(
        alertTitle: "",
        alertContent: S.of(context).transaction_sent,
        buttonText: S.of(context).ok,
        buttonAction: () => Navigator.of(dialogContext).pop(),
      ),
    );

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _showError(BuildContext context, String error) => showPopUp<void>(
        context: context,
        builder: (dialogContext) => AlertWithOneAction(
          alertTitle: S.of(context).error,
          alertContent: error,
          buttonText: S.of(context).ok,
          buttonAction: () => Navigator.of(dialogContext).pop(),
        ),
      );
}

class NFTSendPageArguments {
  NFTSendPageArguments({required this.asset});

  final SolanaNFTAssetModel asset;
}

class _NFTSendConfirmation extends StatelessWidget {
  const _NFTSendConfirmation({
    required this.name,
    required this.mint,
    required this.destinationAddress,
    required this.fee,
    required this.accountCreationFee,
  });

  final String? name;
  final String? mint;
  final String destinationAddress;
  final String fee;
  final String? accountCreationFee;

  @override
  Widget build(BuildContext context) {
    final creationFee = accountCreationFee;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (name?.isNotEmpty ?? false) _ConfirmationRow(label: S.of(context).name, value: name!),
        if (mint?.isNotEmpty ?? false)
          _ConfirmationRow(label: S.of(context).mint_address, value: mint!),
        _ConfirmationRow(label: S.of(context).address, value: destinationAddress),
        _ConfirmationRow(label: S.of(context).send_estimated_fee, value: fee),
        if (creationFee != null)
          Text(
            S.of(context).recipient_account_creation_fee(creationFee),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.none,
                ),
          ),
      ],
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
