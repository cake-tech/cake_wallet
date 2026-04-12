import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/integrations/moonpay/widgets/moonpay_option_row_widget.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/integrations/moonpay_virtual_account/moonpay_virtual_account_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'fiat_option_setup_moonpay_va_page.dart';

class SetupMoonPayVAPage extends BasePage {
  SetupMoonPayVAPage(this.moonPayVirtualAccountViewModel);

  final MoonPayVirtualAccountViewModel moonPayVirtualAccountViewModel;

  @override
  Widget body(BuildContext context) {
    return _MoonPayVirtualAccountBody(viewModel: moonPayVirtualAccountViewModel);
  }
}

class _MoonPayVirtualAccountBody extends StatefulWidget {
  const _MoonPayVirtualAccountBody({required this.viewModel});

  final MoonPayVirtualAccountViewModel viewModel;

  @override
  State<_MoonPayVirtualAccountBody> createState() => _MoonPayVirtualAccountBodyState();
}

class _MoonPayVirtualAccountBodyState extends State<_MoonPayVirtualAccountBody> {
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  final _emailController = TextEditingController();
  String? _emailError;

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final titleTextStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        );

    final textTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        );

    final fiat = widget.viewModel.selectedFiatCurrency;
    final wallet = widget.viewModel.selectedWalletInfo;
    final crypto = widget.viewModel.selectedStablecoinForKeyAndWalletType;
    final walletTypeString = wallet?.type != null ? walletTypeToString(wallet!.type) : 'None';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
              CakeImageWidget(imageUrl: 'assets/images/iron_icon.svg', height: 100, width: 100),
              const SizedBox(height: 40),
              Text('Setup Account', style: titleTextStyle),
              const SizedBox(height: 12),
              Text(
                  'An account will be created with these options. You can change them now, or after account setup.',
                  textAlign: TextAlign.center,
                  style: textTextStyle)
            ],
          ),
          const SizedBox(height: 24),
          OptionCard(
            children: [
              OptionRow(
                icon: fiat.fiatSymbol,
                title: '${fiat.name} Virtual Account',
                subtitle: 'Deposit ${fiat.name}',
                showChevron: true,
              ),
              OptionRow(
                image: crypto?.iconPath,
                title: '$crypto Stablecoin',
                subtitle: 'Receive $crypto',
                showChevron: true,
              ),
              OptionRow(
                image: 'assets/new-ui/navbar/wallets.svg',
                title: '$walletTypeString wallet "${wallet?.name ?? ''}"',
                subtitle: 'Receiving Wallet',
                showChevron: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) {
              setState(() {
                _emailError = _isEmailValid ? null : 'Enter a valid email';
              });
            },
            decoration: InputDecoration(
              hintText: 'email@example.com',
              errorText: _emailError,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainer,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Spacer(),
                Column(
                  children: [
                    Text(
                      'By setting up this account, you agree with this third-party’s terms.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                    ),
                    Text(
                      'View MoonPay’s privacy policy',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                    ),
                    SizedBox(height: 24),
                    PrimaryButton(
                      key: ValueKey('setup_moonpay_va_page_confirm_button_key'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MoonPayVAFiatOptionPage(widget.viewModel),
                          ),
                        );
                      },
                      text: 'Customize',
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      key: ValueKey('setup_moonpay_va_page_continue_button_key'),
                      onPressed: _isEmailValid
                          ? () async {
                              final url = widget.viewModel.createAccountUrl(
                                email: _emailController.text.trim(),
                              );
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            }
                          : null,
                      text: S.of(context).confirm,
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                      isDisabled: !_isEmailValid,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
