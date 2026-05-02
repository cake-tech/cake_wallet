import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/viewmodels/omni_chain_wallet/omni_chain_wallet_bloc.dart';
import 'package:cake_wallet/new-ui/viewmodels/omni_chain_wallet/omni_chain_wallet_event.dart';
import 'package:cake_wallet/new-ui/viewmodels/omni_chain_wallet/omni_chain_wallet_state.dart';
import 'package:cake_wallet/new-ui/widgets/floating_blur_wrapper.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/list_item_regular_row_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/list_item_text_field_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cake_wallet/routes.dart';

class NewChainCustomizationPage extends BasePage {
  NewChainCustomizationPage();

  @override
  String get title => S.current.new_wallet;

  @override
  Widget body(BuildContext context) => NewChainCustomizationPageBody();
}

class NewChainCustomizationPageBody extends StatefulWidget {
  const NewChainCustomizationPageBody({super.key});

  @override
  State<NewChainCustomizationPageBody> createState() => _NewChainCustomizationPageBodyState();
}

class _NewChainCustomizationPageBodyState extends State<NewChainCustomizationPageBody> {
  final TextEditingController _walletNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _walletNameController.addListener(() {
      context.read<OmniChainWalletBloc>().add(
            OmniChainWalletNameChanged(_walletNameController.text),
          );
    });
  }

  @override
  void dispose() {
    _walletNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outlineBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return BlocConsumer<OmniChainWalletBloc, OmniChainWalletState>(
      listener: (context, state) {
        if (_walletNameController.text == state.name) return;

        _walletNameController.text = state.name;
        _walletNameController.selection = TextSelection.fromPosition(
          TextPosition(offset: state.name.length),
        );
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.surfaceContainerLowest,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: 4,
                      child: Material(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            // TODO: add icon picker action
                          },
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.add,
                              size: 22,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Choose the name and icon for your wallet',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              ListItemTextFieldWidget(
                keyValue: 'new_chain_customization_page_wallet_name_row_key',
                controller: _walletNameController,
                label: 'Wallet Name',
                isFirstInSection: true,
                isLastInSection: true,
                height: 60,
                border: outlineBorder,
                enabledBorder: outlineBorder,
                focusedBorder: outlineBorder,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                suffixIcon: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      context.read<OmniChainWalletBloc>().add(
                            OmniChainWalletNameGenerated(),
                          );
                    },
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: CakeImageWidget(
                          imageUrl: 'assets/new-ui/random_icon.svg',
                          width: 18,
                          height: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(999999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999999),
                    onTap: () {
                      // TODO: advanced settings action
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Text(
                        S.of(context).advanced_settings,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: PrimaryButton(
                  key: const ValueKey('new_wallet_customization_continue_button_key'),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      Routes.newOmniChainSummaryPage,
                      arguments: context.read<OmniChainWalletBloc>(),
                    );
                  },
                  borderRadius: BorderRadius.circular(999999),
                  text: S.of(context).continue_text,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                  isDisabled: state.selectedTypes.isEmpty,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
