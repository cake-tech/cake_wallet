import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/dashboard/nft_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class ImportNFTPage extends StatefulWidget {
  const ImportNFTPage({required this.nftViewModel, super.key});

  final NFTViewModel nftViewModel;

  @override
  State<ImportNFTPage> createState() => _ImportNFTPageState();
}

class _ImportNFTPageState extends State<ImportNFTPage> {
  late TextEditingController tokenAddressController;
  late TextEditingController tokenIDController;

  @override
  void initState() {
    super.initState();
    tokenAddressController = TextEditingController();
    tokenIDController = TextEditingController();
  }

  @override
  void dispose() {
    tokenAddressController.dispose();
    tokenIDController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ImportNFTPage(
      nftViewModel: widget.nftViewModel,
      tokenAddressController: tokenAddressController,
      tokenIDController: tokenIDController,
    );
  }
}

class _ImportNFTPage extends BasePage {
  _ImportNFTPage({
    required this.tokenIDController,
    required this.tokenAddressController,
    required this.nftViewModel,
  });

  final NFTViewModel nftViewModel;
  final TextEditingController tokenIDController;
  final TextEditingController tokenAddressController;

  @override
  String? get title => S.current.import;

  @override
  Widget body(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.current.address,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1,
                ),
          ),
          SizedBox(height: 8),
          AddressTextField(
            controller: tokenAddressController,
            options: [AddressTextFieldOption.paste],
            onPushPasteButton: (context) async {
              final clipboard = await Clipboard.getData('text/plain');
              final tokenAddress = clipboard?.text ?? '';

              if (tokenAddress.isNotEmpty) {
                tokenAddressController.text = tokenAddress;
              }
            },
            fillColor: Theme.of(context).colorScheme.surfaceContainer,
            iconColor: Theme.of(context).colorScheme.primary,
            placeholder: '0x...',
            textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (nftViewModel.appStore.wallet!.type != WalletType.solana) ...[
            SizedBox(height: 48),
            Text(
              S.current.tokenID,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1,
                  ),
            ),
            SizedBox(height: 8),
            AddressTextField(
              controller: tokenIDController,
              options: [AddressTextFieldOption.paste],
              onPushPasteButton: (context) async {
                final clipboard = await Clipboard.getData('text/plain');
                final tokenID = clipboard?.text ?? '';

                if (tokenID.isNotEmpty) {
                  tokenIDController.text = tokenID;
                }
              },
              iconColor: Theme.of(context).colorScheme.primary,
              placeholder: S.current.enterTokenID,
              textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          Spacer(),
          Observer(builder: (context) {
            return LoadingPrimaryButton(
              isLoading: nftViewModel.isImportNFTLoading,
              text: S.current.import,
              color: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () async {
                await nftViewModel.importNFT(tokenAddressController.text, tokenIDController.text);
                Navigator.pop(context);
              },
            );
          }),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
