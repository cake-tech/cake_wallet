import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/omnichain_wallet/wallet_creation_type_selection_page.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_creation/omnichain_wallet_creation_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_creation/omnichain_wallet_creation_event.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_creation/omnichain_wallet_creation_state.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/list_item_text_field_widget.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class WalletCreationDetailsPage extends BasePage {
  WalletCreationDetailsPage();

  @override
  String get title => S.current.new_wallet;

  @override
  Widget body(BuildContext context) => const WalletCreationDetailsPageBody();
}

class WalletCreationDetailsPageBody extends StatefulWidget {
  const WalletCreationDetailsPageBody({super.key});

  @override
  State<WalletCreationDetailsPageBody> createState() => _WalletCreationDetailsPageBodyState();
}

class _WalletCreationDetailsPageBodyState extends State<WalletCreationDetailsPageBody> {
  final TextEditingController _walletNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _walletNameController.addListener(() {
      context.read<OmniChainWalletBloc>().add(
            OmniChainWalletGroupNameChanged(_walletNameController.text),
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
    return BlocConsumer<OmniChainWalletBloc, WalletCreationState>(
      listenWhen: (_, current) => current is WalletCreationCustomization,
      listener: (context, state) {
        final groupName = (state as WalletCreationCustomization).groupName;

        if (_walletNameController.text == groupName) {
          return;
        }

        _walletNameController.text = groupName;
        _walletNameController.selection = TextSelection.fromPosition(
          TextPosition(offset: groupName.length),
        );
      },
      buildWhen: (_, current) => current is WalletCreationCustomization,
      builder: (context, rawState) {
        if (rawState is! WalletCreationCustomization) return const SizedBox.shrink();
        final state = rawState;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: state.selectedTypes.length == 1
                    ? Center(
                        child: CakeImageWidget(
                          imageUrl:
                              getCryptoCurrencyIconForWalletListItem(state.selectedTypes.first),
                          width: 100,
                          height: 100,
                        ),
                      )
                    : Stack(
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
                "Choose the name and icon for your wallet",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              ListItemTextFieldWidget(
                keyValue: "new_chain_customization_page_wallet_name_row_key",
                controller: _walletNameController,
                label: "Wallet Name",
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
                            OmniChainWalletGroupNameGenerated(),
                          );
                    },
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: CakeImageWidget(
                          imageUrl: "assets/new-ui/random_icon.svg",
                          width: 18,
                          height: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (state.groupNameError != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    state.groupNameError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ],
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: PrimaryButton(
                  key: const ValueKey("new_wallet_customization_continue_button_key"),
                  onPressed: () {
                    final bloc = context.read<OmniChainWalletBloc>();
                    bloc.add(OmniChainWalletCredentialsSubmitted());
                    Navigator.of(context).pushNamed(
                      Routes.walletCreationSuccessPage,
                      arguments: bloc,
                    );
                  },
                  text: S.of(context).continue_text,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                  isDisabled: !state.canContinue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class OmniChainHowToChangeNetworksSheet extends StatelessWidget {
  const OmniChainHowToChangeNetworksSheet({super.key});

  static Future<void> show(BuildContext context) => showCupertinoModalBottomSheet<void>(
    context: context,
    barrierColor: Colors.black.withAlpha(85),
    builder: (_) => const Material(
      child: OmniChainHowToChangeNetworksSheet(),
    ),
  );

  static const _paragraphs = [
    "You can find the Network Selector on the top left corner of your wallet's homescreen.",
    "That way, you can easily change networks without having to navigate to a different tab on Cake Wallet.",
    "If you are familiar with Wallet Groups, this is an improved navigation for them.",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ModalTopBar(
          title: "How to Change Network",
          leadingIcon: const Icon(Icons.arrow_back_ios_new),
          onLeadingPressed: Navigator.of(context).pop,
          leadingSemanticLabel: S.of(context).close,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FrameIconWidget(iconSize: 96),
              const SizedBox(height: 36),
              ..._paragraphs.map(
                    (paragraph) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    paragraph,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
