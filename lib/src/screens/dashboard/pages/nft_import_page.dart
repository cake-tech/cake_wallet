import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/extensions/seed_widget_theme.dart';
import 'package:cake_wallet/view_model/dashboard/nft_view_model.dart';
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
  String? get title => 'Import NFT';

  @override
  Widget body(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w800,
              color: Theme.of(context).extension<SeedWidgetTheme>()!.hintTextColor,
              height: 1,
            ),
          ),
          BaseTextFormField(
            suffixIcon: PasteTextWidget(
              onTap: () async {
                final clipboard = await Clipboard.getData('text/plain');
                final tokenAddress = clipboard?.text ?? '';

                if (tokenAddress.isNotEmpty) {
                  tokenAddressController.text = tokenAddress;
                }
              },
            ),
            textAlign: TextAlign.left,
            hintText: '0x...',
            controller: tokenAddressController,
            keyboardType: TextInputType.number,
            placeholderTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 48),
          Text(
            'ID',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w800,
              color: Theme.of(context).extension<SeedWidgetTheme>()!.hintTextColor,
              height: 1,
            ),
          ),
          BaseTextFormField(
            textAlign: TextAlign.left,
            hintText: 'Enter the token ID',
            controller: tokenIDController,
            keyboardType: TextInputType.number,
            suffixIcon: PasteTextWidget(
              onTap: () async {
                final clipboard = await Clipboard.getData('text/plain');
                final tokenID = clipboard?.text ?? '';

                if (tokenID.isNotEmpty) {
                  tokenIDController.text = tokenID;
                }
              },
            ),
            placeholderTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          Spacer(),
          Observer(builder: (context) {
            return LoadingPrimaryButton(
              isLoading: nftViewModel.isImportNFTLoading,
              text: 'IMPORT',
              color: Theme.of(context).primaryColor,
              textColor: Colors.white,
              onPressed: () async {
                await nftViewModel.importNFT(tokenAddressController.text, tokenIDController.text);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}

class PasteTextWidget extends StatelessWidget {
  const PasteTextWidget({
    required this.onTap,
    super.key,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Image.asset(
            'assets/images/paste_ios.png',
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
