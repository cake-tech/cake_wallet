import 'package:cake_wallet/entities/default_settings_migration.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/seed_phrase_length.dart';
import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import "package:cake_wallet/new-ui/viewmodels/restore_wallet/seed_settings_cubit.dart";
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_form.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_choices_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scrollable_with_bottom_section.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/view_model/advanced_privacy_settings_view_model.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/zcash/zcash_network_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class AdvancedPrivacySettingsPage extends BasePage {
  AdvancedPrivacySettingsPage({
    required this.isFromRestore,
    required this.isChildWallet,
    required this.useTestnet,
    required this.toggleUseTestnet,
    required this.zcashNetwork,
    required this.setZcashNetwork,
    required this.advancedPrivacySettingsViewModel,
    required this.nodeViewModel,
  });

  final AdvancedPrivacySettingsViewModel advancedPrivacySettingsViewModel;
  final NodeCreateOrEditViewModel nodeViewModel;

  @override
  String get title => S.current.privacy_settings;

  final bool isFromRestore;
  final bool isChildWallet;
  final bool useTestnet;
  final Function(bool? val) toggleUseTestnet;
  final int zcashNetwork;
  final void Function(int network) setZcashNetwork;

  @override
  Widget body(BuildContext context) => _AdvancedPrivacySettingsBody(
        isFromRestore,
        isChildWallet,
        useTestnet,
        toggleUseTestnet,
        zcashNetwork,
        setZcashNetwork,
        advancedPrivacySettingsViewModel,
        nodeViewModel,
      );
}

class _AdvancedPrivacySettingsBody extends StatefulWidget {
  const _AdvancedPrivacySettingsBody(
    this.isFromRestore,
    this.isChildWallet,
    this.useTestnet,
    this.toggleUseTestnet,
    this.zcashNetwork,
    this.setZcashNetwork,
    this.privacySettingsViewModel,
    this.nodeViewModel,
  );

  final AdvancedPrivacySettingsViewModel privacySettingsViewModel;
  final NodeCreateOrEditViewModel nodeViewModel;

  final bool isFromRestore;
  final bool isChildWallet;
  final bool useTestnet;
  final Function(bool? val) toggleUseTestnet;
  final int zcashNetwork;
  final void Function(int network) setZcashNetwork;

  @override
  _AdvancedPrivacySettingsBodyState createState() => _AdvancedPrivacySettingsBodyState();
}

class _AdvancedPrivacySettingsBodyState extends State<_AdvancedPrivacySettingsBody> {
  late final SeedSettingsCubit _seedSettingsCubit = context.read<SeedSettingsCubit>();

  final TextEditingController passphraseController = TextEditingController();
  final TextEditingController confirmPassphraseController = TextEditingController();
  final _formKey = GlobalKey<NodeFormState>();
  final _passphraseFormKey = GlobalKey<FormState>();
  bool? testnetValue;
  int? zcashNetworkValue;

  bool obscurePassphrase = true;

  @override
  void initState() {
    passphraseController.text = _seedSettingsCubit.state.passphrase ?? '';
    confirmPassphraseController.text = _seedSettingsCubit.state.passphrase ?? '';

    if (widget.isChildWallet) {
      if (widget.privacySettingsViewModel.type == WalletType.bitcoin) {
        _seedSettingsCubit.setBitcoinSeedType(BitcoinSeedType.bip39);
      }

      if (widget.privacySettingsViewModel.type == WalletType.nano) {
        _seedSettingsCubit.setNanoSeedType(NanoSeedType.bip39);
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    passphraseController.dispose();
    confirmPassphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (testnetValue == null && widget.useTestnet) {
      testnetValue = widget.useTestnet;
    }
    zcashNetworkValue ??= widget.zcashNetwork;

    return Container(
      padding: EdgeInsets.only(top: 24),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.only(bottom: 24),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Observer(builder: (_) {
              return SettingsChoicesCell(
                ChoicesListItem<FiatApiMode>(
                  title: S.current.fiat_api,
                  items: FiatApiMode.all,
                  selectedItem: widget.privacySettingsViewModel.fiatApiMode,
                  onItemSelected: (FiatApiMode mode) =>
                      widget.privacySettingsViewModel.setFiatApiMode(mode),
                ),
              );
            }),
            Observer(builder: (_) {
              return SettingsChoicesCell(
                ChoicesListItem<ExchangeApiMode>(
                  title: S.current.swap,
                  items: ExchangeApiMode.all,
                  selectedItem: widget.privacySettingsViewModel.exchangeStatus,
                  onItemSelected: (ExchangeApiMode mode) =>
                      widget.privacySettingsViewModel.setExchangeApiMode(mode),
                ),
              );
            }),
            if (widget.privacySettingsViewModel.isMoneroSeedTypeOptionsEnabled &&
                !widget.isChildWallet)
              BlocSelector<SeedSettingsCubit, SeedSettingsState, MoneroSeedType>(
                selector: (state) => state.moneroSeedType,
                builder: (context, moneroSeedType) {
                  return SettingsChoicesCell(
                    ChoicesListItem<MoneroSeedType>(
                      title: S.current.seedtype,
                      items: MoneroSeedType.all,
                      selectedItem: moneroSeedType,
                      onItemSelected: _seedSettingsCubit.setMoneroSeedType,
                      displayItem: (seedType) => seedType.shortTitle ?? seedType.toString(),
                    ),
                  );
                },
              ),
            if (widget.privacySettingsViewModel.isBitcoinSeedTypeOptionsEnabled)
              BlocSelector<SeedSettingsCubit, SeedSettingsState, BitcoinSeedType>(
                selector: (state) => state.bitcoinSeedType,
                builder: (context, bitcoinSeedType) {
                  return SettingsChoicesCell(
                    ChoicesListItem<BitcoinSeedType>(
                      title: S.current.seedtype,
                      items: BitcoinSeedType.all,
                      selectedItem: bitcoinSeedType,
                      onItemSelected: (type) {
                        if (widget.isChildWallet && type != BitcoinSeedType.bip39) {
                          showAlertForSelectingNonBIP39DerivationTypeForChildWallets();
                        } else {
                          _seedSettingsCubit.setBitcoinSeedType(type);
                        }
                      },
                    ),
                  );
                },
              ),
            if (widget.privacySettingsViewModel.isNanoSeedTypeOptionsEnabled)
              BlocSelector<SeedSettingsCubit, SeedSettingsState, NanoSeedType>(
                selector: (state) => state.nanoSeedType,
                builder: (context, nanoSeedType) {
                  return SettingsChoicesCell(
                    ChoicesListItem<NanoSeedType>(
                      title: S.current.seedtype,
                      items: NanoSeedType.all,
                      selectedItem: nanoSeedType,
                      onItemSelected: (type) {
                        if (widget.isChildWallet && type != NanoSeedType.bip39) {
                          showAlertForSelectingNonBIP39DerivationTypeForChildWallets();
                        } else {
                          _seedSettingsCubit.setNanoSeedType(type);
                        }
                      },
                    ),
                  );
                },
              ),
            if (!widget.isFromRestore)
              Observer(builder: (_) {
                if (widget.privacySettingsViewModel.hasSeedPhraseLengthOption)
                  return SettingsPickerCell<SeedPhraseLength>(
                    title: S.current.seed_phrase_length,
                    items: SeedPhraseLength.values,
                    selectedItem: widget.privacySettingsViewModel.seedPhraseLength,
                    onItemSelected: (SeedPhraseLength length) {
                      widget.privacySettingsViewModel.setSeedPhraseLength(length);
                    },
                  );
                return Container();
              }),
            if (widget.privacySettingsViewModel.hasPassphraseOption && !widget.isFromRestore)
              Padding(
                padding: EdgeInsets.all(24),
                child: Form(
                  key: _passphraseFormKey,
                  child: Column(
                    children: [
                      BaseTextFormField(
                        hintText: S.of(context).passphrase,
                        controller: passphraseController,
                        obscureText: obscurePassphrase,
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() {
                            obscurePassphrase = !obscurePassphrase;
                          }),
                          child: Icon(
                            Icons.remove_red_eye,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      BaseTextFormField(
                        hintText: S.of(context).confirm_passphrase,
                        controller: confirmPassphraseController,
                        obscureText: obscurePassphrase,
                        validator: (text) {
                          if (text == passphraseController.text) {
                            return null;
                          }

                          return S.of(context).passphrases_doesnt_match;
                        },
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() {
                            obscurePassphrase = !obscurePassphrase;
                          }),
                          child: Icon(
                            Icons.remove_red_eye,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Observer(builder: (_) {
              return Column(
                children: [
                  SettingsSwitcherCell(
                    title: S.current.disable_bulletin,
                    value: widget.privacySettingsViewModel.disableBulletin,
                    onValueChange: (BuildContext _, bool value) {
                      widget.privacySettingsViewModel.setDisableBulletin(value);
                    },
                  ),
                  if (widget.privacySettingsViewModel.canUseBlinkProtection)
                    SettingsSwitcherCell(
                      title: S.current.use_blink_protection,
                      value: widget.privacySettingsViewModel.useBlinkProtection,
                      onValueChange: (BuildContext _, bool value) {
                        widget.privacySettingsViewModel.setUseBlinkProtection(value);
                      },
                    ),
                  SettingsSwitcherCell(
                    title: S.current.add_custom_node,
                    value: widget.privacySettingsViewModel.addCustomNode,
                    onValueChange: (_, __) => widget.privacySettingsViewModel.toggleAddCustomNode(),
                  ),
                  if (widget.privacySettingsViewModel.addCustomNode)
                    Padding(
                      padding: EdgeInsets.only(left: 24, right: 24, top: 24),
                      child: NodeForm(
                        key: _formKey,
                        nodeViewModel: widget.nodeViewModel,
                      ),
                    )
                ],
              );
            }),
            if (FeatureFlag.hasDevOptions &&
                widget.privacySettingsViewModel.type == WalletType.zcash)
              SettingsChoicesCell(
                ChoicesListItem<int>(
                  title: 'Zcash network',
                  items: ZcashNetworkType.values,
                  selectedItem: zcashNetworkValue ?? ZcashNetworkType.mainnet,
                  displayItem: ZcashNetworkType.label,
                  onItemSelected: (final network) {
                    setState(() => zcashNetworkValue = network);
                    widget.setZcashNetwork(network);
                  },
                ),
              ),
            if (widget.privacySettingsViewModel.type == WalletType.bitcoin ||
                widget.privacySettingsViewModel.type == WalletType.decred)
              Builder(builder: (_) {
                final val = testnetValue ?? false;
                return SettingsSwitcherCell(
                    title: S.current.use_testnet,
                    value: val,
                    onValueChange: (_, __) {
                      setState(() {
                        testnetValue = !val;
                      });
                      widget.toggleUseTestnet.call(testnetValue);
                    });
              }),
          ],
        ),
        bottomSectionPadding: EdgeInsets.all(24),
        bottomSection: Column(
          children: [
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (_, constraints) => SizedBox(
                width: constraints.maxWidth * 0.8,
                child: Text(
                  S.of(context).settings_can_be_changed_later,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            LoadingPrimaryButton(
              onPressed: () async {
                if (widget.privacySettingsViewModel.addCustomNode) {
                  if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
                    return;
                  }

                  await widget.nodeViewModel.save();
                  widget.nodeViewModel.setAsCurrent(widget.nodeViewModel.editingNode!);
                }
                if (testnetValue == true &&
                    widget.privacySettingsViewModel.type == WalletType.bitcoin) {
                  // TODO: add type (mainnet/testnet) to Node class so when switching wallets the node can be switched to a matching type
                  // Currently this is so you can create a working testnet wallet but you need to keep switching back the node if you use multiple wallets at once
                  widget.nodeViewModel.address = publicBitcoinTestnetElectrumAddress;
                  widget.nodeViewModel.port = publicBitcoinTestnetElectrumPort;

                  await widget.nodeViewModel.save();
                }
                if (_passphraseFormKey.currentState != null &&
                    !_passphraseFormKey.currentState!.validate()) {
                  return;
                }

                _seedSettingsCubit.setPassphrase(passphraseController.text);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              text: S.of(context).continue_text,
              color: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onPrimary,
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void showAlertForSelectingNonBIP39DerivationTypeForChildWallets() {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithOneAction(
            alertTitle: S.current.seedtype_alert_title,
            alertContent: S.current.seedtype_alert_content,
            buttonText: S.of(context).ok,
            buttonAction: () => Navigator.of(context).pop(),
          );
        });
  }
}
