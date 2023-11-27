import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
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
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w800,
              color:
                  Theme.of(context).extension<SeedWidgetTheme>()!.hintTextColor,
              height: 1,
            ),
          ),
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
            borderColor: Theme.of(context)
                .extension<CakeTextTheme>()!
                .textfieldUnderlineColor,
            iconColor: Theme.of(context).primaryColor,
            placeholder: '0x...',
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: PaletteDark.darkCyanBlue,
            ),
            hintStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: PaletteDark.darkCyanBlue,
            ),
          ),
      
          SizedBox(height: 48),
          Text(
            S.current.tokenID,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w800,
              color: Theme.of(context).extension<SeedWidgetTheme>()!.hintTextColor,
              height: 1,
            ),
          ),
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
            borderColor: Theme.of(context)
                .extension<CakeTextTheme>()!
                .textfieldUnderlineColor,
            iconColor: Theme.of(context).primaryColor,
            placeholder: S.current.enterTokenID,
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: PaletteDark.darkCyanBlue,
            ),
            hintStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: PaletteDark.darkCyanBlue,
            ),
          ),
          Spacer(),
          Observer(builder: (context) {
            return LoadingPrimaryButton(
              isLoading: nftViewModel.isImportNFTLoading,
              text: S.current.import,
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
