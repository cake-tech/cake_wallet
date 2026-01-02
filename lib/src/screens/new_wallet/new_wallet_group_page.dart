import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/core/wallet_name_validator.dart';
import 'package:cake_wallet/entities/generate_name.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/new_wallet_group_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class NewWalletGroupPage extends BasePage {
  NewWalletGroupPage(this._walletGroupVM);

  final WalletGroupNewVM _walletGroupVM;

  final welcomeImageLight = 'assets/images/wallet_group_empty_light.png';
  final welcomeImageDark = 'assets/images/wallet_group_empty_dark.png';

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) =>
          GradientBackground(scaffold: scaffold);

  @override
  String get title => S.current.new_wallet_group;

  @override
  Function(BuildContext)? get pushToNextWidget => (context) {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.focusedChild?.unfocus();
        }
      };

  @override
  Widget body(BuildContext context) => WalletNameForm(_walletGroupVM,
      currentTheme.isDark ? welcomeImageDark : welcomeImageLight);
}

class WalletNameForm extends StatefulWidget {
  WalletNameForm(this._walletGroupVM, this.walletImage);

  final WalletGroupNewVM _walletGroupVM;
  final String walletImage;

  @override
  _WalletNameFormState createState() => _WalletNameFormState(_walletGroupVM);
}

class _WalletNameFormState extends State<WalletNameForm> {
  _WalletNameFormState(this._walletGroupVM)
      : _formKey = GlobalKey<FormState>(),
        _nameController = TextEditingController();

  static const aspectRatioImage = 1.5;
  bool _formProcessing = false;

  final GlobalKey<FormState> _formKey;
  final WalletGroupNewVM _walletGroupVM;
  final TextEditingController _nameController;
  ReactionDisposer? _stateReaction;

  @override
  void initState() {
    _stateReaction ??=
        reaction((_) => _walletGroupVM.state, (ExecutionState state) async {
      if (state is ExecutedSuccessfullyState) {
        final payload = state.payload;
        final walletGroupParams = payload is WalletGroupParams ? payload : null;

        final excludedTypes = walletGroupParams?.excludedTypes ?? [];


        if (excludedTypes.isNotEmpty) {
          final navContext = navigatorKey.currentContext ?? context;
          await showPopUp<void>(
            context: navContext,
            builder: (_) => AlertWithOneAction(
              key: const ValueKey('new_wallet_group_page_excluded_types_dialog_key'),
              buttonKey: const ValueKey('new_wallet_group_page_excluded_types_dialog_button_key'),
              alertTitle: S.current.alert_notice,
              alertContent:
              'The following wallet types were excluded from the group due to passphrase requirements:\n'
                  '${excludedTypes.map((e) => walletTypeToDisplayName(e)).join(', ')}',
              buttonText: S.of(navContext).ok,
              buttonAction: () => Navigator.of(navContext).pop(),
            ),
          );
        }

        Navigator.of(navigatorKey.currentContext ?? context)
            .pushNamed(Routes.preSeedPage);

        // Start creating the rest of the wallets after navigation
        if (walletGroupParams != null) {
          Future<void>(() async {
            await widget._walletGroupVM
                .createRestWallets(walletGroupParams);
          });
        }
      }

      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showPopUp<void>(
                context: context,
                builder: (_) {
                  return AlertWithOneAction(
                    key: ValueKey('new_wallet_group_page_failure_dialog_key'),
                    buttonKey:
                        ValueKey('new_wallet_group_page_failure_dialog_button_key'),
                    alertTitle: S.current.new_wallet,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop(),
                  );
                });
          }
        });
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 24),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
        content: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 24, right: 12),
                  child: AspectRatio(
                    aspectRatio: aspectRatioImage,
                    child: FittedBox(
                      child: CakeImageWidget(imageUrl: widget.walletImage),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 48),
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        BaseTextFormField(
                          key: ValueKey(
                              'new_wallet_group_page_wallet_name_textformfield_key'),
                          onChanged: (value) => _walletGroupVM.name = value,
                          controller: _nameController,
                          textStyle: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          placeholderTextStyle:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    height: 1.4,
                                    fontSize: 16.0,
                                  ),
                          hintText: S.of(context).wallet_group_name,
                          suffixIcon: Semantics(
                            label: S.of(context).generate_name,
                            child: IconButton(
                              key: ValueKey(
                                'new_wallet_group_page_wallet_name_textformfield_generate_name_button_key',
                              ),
                              onPressed: () async {
                                final rName = await generateName();
                                FocusManager.instance.primaryFocus?.unfocus();

                                setState(() {
                                  _nameController.text = rName;
                                  _walletGroupVM.name = rName;
                                  _nameController.selection =
                                      TextSelection.fromPosition(
                                    TextPosition(
                                        offset: _nameController.text.length),
                                  );
                                });
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6.0),
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                                width: 34,
                                height: 34,
                                child: Image.asset(
                                    'assets/images/refresh_icon.png',
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                            ),
                          ),
                          validator: WalletNameValidator(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomSectionPadding: EdgeInsets.all(24),
        bottomSection: Column(
          children: [
            PrimaryButton(
              key: ValueKey('new_wallet_group_page_advanced_settings_button_key'),
              onPressed: () {
                Navigator.of(context).pushNamed(Routes.advancedPrivacySettings, arguments: {
                  "type": WalletType.none,
                  "useTestnet": false,
                  "toggleTestnet": (bool? _) {},
                  "isChildWallet": false,
                });
              },
              text: S.of(context).advanced_settings,
              color: Theme.of(context).colorScheme.surfaceContainer,
              textColor: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(height: 12),
            Observer(
              builder: (context) {
                return LoadingPrimaryButton(
                  key: ValueKey('new_wallet_group_page_confirm_button_key'),
                  onPressed: _confirmForm,
                  text: S.of(context).seed_language_next,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                  isLoading: _walletGroupVM.state is IsExecutingState,
                  isDisabled: _walletGroupVM.name.isEmpty,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmForm() async {
    if (_formProcessing) return;
    _formProcessing = true;
    try {
      if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
        _formProcessing = false;
        return;
      }

      if (_walletGroupVM.groupNameExists(_walletGroupVM.name)) {
        await showPopUp<void>(
            context: context,
            builder: (_) {
              return AlertWithOneAction(
                  alertTitle: '',
                  alertContent: S.of(context).wallet_name_exists,
                  buttonText: S.of(context).ok,
                  buttonAction: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  });
            });
      } else {
        await _walletGroupVM.createNewGroup(options: null);
      }
    } catch (e) {
      _formProcessing = false;
      rethrow;
    }
    _formProcessing = false;
  }
}
