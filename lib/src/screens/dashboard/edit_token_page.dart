import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/checkbox_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/warning_box_widget.dart';
import 'package:cake_wallet/themes/core/custom_theme_colors.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/home_settings_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class EditTokenPage extends BasePage {
  EditTokenPage({
    Key? key,
    required this.homeSettingsViewModel,
    this.token,
    this.initialContractAddress,
  }) : assert(token == null || initialContractAddress == null);

  final HomeSettingsViewModel homeSettingsViewModel;
  final CryptoCurrency? token;
  final String? initialContractAddress;

  @override
  String? get title => (token != null || initialContractAddress != null)
      ? S.current.edit_token
      : S.current.add_token;

  @override
  Widget body(BuildContext context) {
    return EditTokenPageBody(
      homeSettingsViewModel: homeSettingsViewModel,
      token: token,
      initialContractAddress: initialContractAddress,
    );
  }
}

class EditTokenPageBody extends StatefulWidget {
  const EditTokenPageBody({
    Key? key,
    required this.homeSettingsViewModel,
    this.token,
    this.initialContractAddress,
  }) : super(key: key);

  final HomeSettingsViewModel homeSettingsViewModel;
  final CryptoCurrency? token;
  final String? initialContractAddress;

  @override
  State<EditTokenPageBody> createState() => _EditTokenPageBodyState();
}

class _EditTokenPageBodyState extends State<EditTokenPageBody> {
  final TextEditingController _contractAddressController = TextEditingController();
  final TextEditingController _tokenNameController = TextEditingController();
  final TextEditingController _tokenSymbolController = TextEditingController();
  final TextEditingController _tokenDecimalController = TextEditingController();
  final TextEditingController _tokenIconPathController = TextEditingController();

  final FocusNode _contractAddressFocusNode = FocusNode();
  final FocusNode _tokenNameFocusNode = FocusNode();
  final FocusNode _tokenSymbolFocusNode = FocusNode();
  final FocusNode _tokenDecimalFocusNode = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _showDisclaimer = false;
  bool _disclaimerChecked = false;
  bool isEditingToken = false;
  bool _isTokenVerified = false;

  @override
  void initState() {
    super.initState();

    String? address;

    if (widget.token != null) {
      address = widget.homeSettingsViewModel.getTokenAddressBasedOnWallet(widget.token!);

      _contractAddressController.text = address ?? '';
      _tokenNameController.text = widget.token!.name;
      _tokenSymbolController.text = widget.token!.title;
      _tokenDecimalController.text = widget.token!.decimals.toString();
      _tokenIconPathController.text = widget.token?.iconPath ?? '';

      isEditingToken = true;

      _checkIfTokenIsVerified(address);
    }

    if (widget.initialContractAddress != null) {
      _contractAddressController.text = widget.initialContractAddress!;
      _getTokenInfo();
    }

    _contractAddressFocusNode.addListener(() {
      if (!_contractAddressFocusNode.hasFocus) {
        _getTokenInfo();
      }

      final contractAddress = _contractAddressController.text;
      if (contractAddress.isNotEmpty && contractAddress != address) {
        setState(() {
          _showDisclaimer = true;
        });
      }
    });
  }

  void _checkIfTokenIsVerified(String? contractAddress) {
    if (contractAddress == null) return;

    final isVerified = widget.homeSettingsViewModel.checkIfTokenIsWhitelisted(contractAddress);

    if (!mounted) return;
    setState(() {
      _isTokenVerified = isVerified;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.zero,
        content: Padding(
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              SizedBox(height: 30),
              WarningBox(
                padding: EdgeInsets.all(16),
                content: S.of(context).add_token_warning,
                showBorder: false,
                textWeight: FontWeight.w500,
                textAlign: TextAlign.start,
                textColor: context.customColors.warningOutlineColor,
                iconSize: 22,
                iconSpacing: 16,
              ),
              SizedBox(height: 50),
              _tokenForm(),
            ],
          ),
        ),
        bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 48),
        bottomSection: Column(
          children: [
            if (_showDisclaimer) ...[
              CheckboxWidget(
                value: _disclaimerChecked,
                caption: S.of(context).add_token_disclaimer_check,
                onChanged: (value) {
                  _disclaimerChecked = value;
                },
              ),
              SizedBox(height: 20),
            ],
            Observer(
              builder: (context) {
                return Row(
                  children: <Widget>[
                    Expanded(
                      child: LoadingPrimaryButton(
                        isLoading: widget.homeSettingsViewModel.isDeletingToken,
                        onPressed: () async {
                          if (widget.token != null) {
                            await widget.homeSettingsViewModel.deleteToken(widget.token!);
                          }
                          Navigator.pop(context);
                        },
                        text: widget.token != null ? S.of(context).delete : S.of(context).cancel,
                        color: isEditingToken
                            ? Theme.of(context).colorScheme.errorContainer
                            : Theme.of(context).colorScheme.surfaceContainer,
                        textColor: isEditingToken
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: LoadingPrimaryButton(
                        isLoading: widget.homeSettingsViewModel.isAddingToken ||
                            widget.homeSettingsViewModel.isValidatingContractAddress,
                        onPressed: () async {
                          if (_formKey.currentState!.validate() &&
                              (!_showDisclaimer || _disclaimerChecked)) {
                            final isTokenAlreadyAdded = isEditingToken
                                ? false
                                : await widget.homeSettingsViewModel
                                    .checkIfTokenIsAlreadyAdded(_contractAddressController.text);
                            if (isTokenAlreadyAdded) {
                              showPopUp<void>(
                                context: context,
                                builder: (dialogContext) {
                                  return AlertWithOneAction(
                                    alertTitle: S.current.warning,
                                    alertContent: S.of(context).token_already_exists,
                                    buttonText: S.of(context).ok,
                                    buttonAction: () => Navigator.of(dialogContext).pop(),
                                  );
                                },
                              );
                              return;
                            }

                            final isWhitelisted = await widget.homeSettingsViewModel
                                .checkIfTokenIsWhitelisted(_contractAddressController.text);

                            final hasPotentialError = !isWhitelisted &&
                                await widget.homeSettingsViewModel
                                    .checkIfERC20TokenContractAddressIsAPotentialScamAddress(
                                  _contractAddressController.text,
                                );

                            bool isPotentialScam = hasPotentialError && !isWhitelisted;
                            final tokenSymbol = _tokenSymbolController.text.toUpperCase();

                            // check if the token symbol is the same as any of the base currencies symbols (ETH, SOL, POL, TRX, etc):
                            // if it is, then it's probably a scam unless it's in the whitelist

                            // ugh, should it be commented out?
                            // because there are some tokens that has the name of original currencies
                            // like: 0x455e53CBB86018Ac2B8092FdCd39d8444aFFC3F6

                            final baseCurrencySymbols =
                                CryptoCurrency.all.map((e) => e.title.toUpperCase()).toList();
                            if (baseCurrencySymbols.contains(tokenSymbol.trim().toUpperCase()) &&
                                !isWhitelisted) {
                              isPotentialScam = true;
                            }

                            final actionCall = () async {
                              try {
                                await widget.homeSettingsViewModel.addToken(
                                  token: CryptoCurrency(
                                    name: _tokenNameController.text,
                                    title: _tokenSymbolController.text.toUpperCase(),
                                    decimals: int.parse(_tokenDecimalController.text),
                                    iconPath: _tokenIconPathController.text.isNotEmpty
                                        ? _tokenIconPathController.text
                                        : null,
                                    isPotentialScam: isPotentialScam,
                                  ),
                                  contractAddress: _contractAddressController.text,
                                );

                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                showPopUp<void>(
                                  context: context,
                                  builder: (dialogContext) {
                                    return AlertWithOneAction(
                                      alertTitle: S.current.warning,
                                      alertContent: e.toString(),
                                      buttonText: S.of(context).ok,
                                      buttonAction: () => Navigator.of(dialogContext).pop(),
                                    );
                                  },
                                );
                              }
                            };

                            if (hasPotentialError && !isWhitelisted) {
                              showPopUp<void>(
                                context: context,
                                builder: (dialogContext) {
                                  return AlertWithTwoActions(
                                    alertTitle: S.current.warning,
                                    alertContent: S.current.contract_warning,
                                    rightButtonText: S.of(context).continue_text,
                                    leftButtonText: S.of(context).cancel,
                                    actionRightButton: () async {
                                      Navigator.of(dialogContext).pop();
                                      await actionCall();
                                    },
                                    actionLeftButton: () => Navigator.of(dialogContext).pop(),
                                  );
                                },
                              );
                            } else {
                              try {
                                await actionCall();
                              } catch (e) {
                                showPopUp<void>(
                                  context: context,
                                  builder: (dialogContext) {
                                    return AlertWithOneAction(
                                      alertTitle: "Unable to add token",
                                      alertContent: "$e",
                                      buttonText: S.of(context).ok,
                                      buttonAction: () => Navigator.of(context).pop(),
                                    );
                                  },
                                );
                              }
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            }
                          }
                        },
                        text: S.of(context).save,
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _getTokenInfo() async {
    if (_contractAddressController.text.isNotEmpty) {
      final token = await widget.homeSettingsViewModel.getToken(_contractAddressController.text);

      if (!mounted) return;

      if (token != null) {
        final isZano = widget.homeSettingsViewModel.walletType == WalletType.zano;
        if (_tokenNameController.text.isEmpty || isZano) _tokenNameController.text = token.name;
        if (_tokenSymbolController.text.isEmpty || isZano)
          _tokenSymbolController.text = token.title;
        if (_tokenIconPathController.text.isEmpty)
          _tokenIconPathController.text = token.iconPath ?? '';
        if (_tokenDecimalController.text.isEmpty || isZano)
          _tokenDecimalController.text = token.decimals.toString();

        _checkIfTokenIsVerified(_contractAddressController.text);
      }
    }
  }

  Future<void> _pasteText() async {
    final value = await Clipboard.getData('text/plain');

    if (value?.text?.isNotEmpty ?? false) {
      _contractAddressController.text = value!.text!;

      _getTokenInfo();
      setState(() {
        _showDisclaimer = true;
      });
    }
  }

  Widget _tokenForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _tokenIconPathController.text.isEmpty
              ? DottedBorder(
                  borderType: BorderType.Circle,
                  dashPattern: [6, 4],
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  strokeWidth: 2,
                  radius: Radius.circular(15),
                  child: Container(width: 75, height: 75),
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipOval(
                      child: CakeImageWidget(
                        imageUrl: _tokenIconPathController.text,
                        width: 75,
                        height: 75,
                      ),
                    ),
                    if (_isTokenVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
          SizedBox(height: 25),
          AddressTextField(
            controller: _contractAddressController,
            focusNode: _contractAddressFocusNode,
            placeholder: S.of(context).contract_address,
            copyImagePath: 'assets/images/copy.png',
            options: [AddressTextFieldOption.paste],
            validator: widget.homeSettingsViewModel.walletType == WalletType.zano
                ? null
                : AddressValidator(type: widget.homeSettingsViewModel.nativeToken).call,
            onPushPasteButton: (_) {
              _pasteText();
            },
          ),
          const SizedBox(height: 16),
          isEditingToken
              ? WarningBox(
                  padding: EdgeInsets.all(16),
                  content: S.of(context).tokens_strong_warning,
                  showBorder: false,
                  textWeight: FontWeight.w500,
                  textColor: context.customColors.warningOutlineColor,
                  showIcon: false,
                )
              : Text(
                  S.of(context).tokens_strong_warning,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
          const SizedBox(height: 24),
          Divider(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            height: 1,
          ),
          const SizedBox(height: 24),
          BaseTextFormField(
            controller: _tokenNameController,
            focusNode: _tokenNameFocusNode,
            onSubmit: (_) => FocusScope.of(context).requestFocus(_tokenSymbolFocusNode),
            textInputAction: TextInputAction.next,
            hintText: S.of(context).token_name,
            validator: (text) {
              if (text?.isNotEmpty ?? false) {
                return null;
              }

              return S.of(context).field_required;
            },
          ),
          const SizedBox(height: 10),
          BaseTextFormField(
            controller: _tokenSymbolController,
            focusNode: _tokenSymbolFocusNode,
            onSubmit: (_) => FocusScope.of(context).requestFocus(_tokenDecimalFocusNode),
            textInputAction: TextInputAction.next,
            hintText: S.of(context).token_symbol,
            validator: (text) {
              if (text?.isNotEmpty ?? false) {
                return null;
              }

              return S.of(context).field_required;
            },
          ),
          const SizedBox(height: 10),
          BaseTextFormField(
            controller: _tokenDecimalController,
            focusNode: _tokenDecimalFocusNode,
            textInputAction: TextInputAction.done,
            hintText: S.of(context).token_decimal,
            validator: (text) {
              if (text?.isEmpty ?? true) {
                return S.of(context).field_required;
              }

              if (int.tryParse(text!) == null) {
                return S.of(context).invalid_input;
              }

              if (int.tryParse(text) == 0) {
                return S.current.decimals_cannot_be_zero;
              }

              return null;
            },
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
