import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/ethereum_staking/ethereum_staking_amount_page.dart";
import "package:cake_wallet/new-ui/viewmodels/ethereum_staking/ethereum_staking_bloc.dart";
import "package:cake_wallet/new-ui/widgets/ethereum_staking/ethereum_staking_rows.dart";
import "package:cake_wallet/new-ui/widgets/ethereum_staking/everstake_terms_text.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class EthereumStakingIntroPage extends StatelessWidget {
  const EthereumStakingIntroPage({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) => BlocBuilder<EthereumStakingBloc, EthereumStakingState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          final data = state.data!;

          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  ModalTopBar(
                    title: "",
                    leadingIcon: const Icon(Icons.close),
                    leadingSemanticLabel: S.of(context).close,
                    onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 32, 18, 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CakeImageWidget(
                                  imageUrl: "assets/new-ui/everstake_wordmark.svg",
                                  width: 234.922,
                                  height: 37.3,
                                  color: theme.colorScheme.onSurface,
                                  semanticsLabel: "Everstake",
                                ),
                                const SizedBox(height: 48),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 27),
                                  child: Text(
                                    data.apr == null
                                        ? S.of(context).everstake_intro
                                        : S.of(context).everstake_intro_apr(
                                              stakingAprText(context, data.apr!),
                                            ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                NewListSections(
                                  sections: {
                                    "everstake": [
                                      everstakeProviderRow(context),
                                      if (data.apr != null) stakingYieldRow(context, data.apr!),
                                      if (data.activationTime != null)
                                        stakingActivationRow(context, data.activationTime!),
                                      stakingServiceFeeRow(context, data.poolFee),
                                    ],
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: Column(
                      spacing: 16,
                      children: [
                        EverstakeTermsText(S.of(context).everstake_terms_by_continuing),
                        NewPrimaryButton(
                          onPressed: () => Navigator.of(context).push(
                            CupertinoPageRoute<void>(
                              builder: (_) => Material(
                                color: Colors.transparent,
                                child: EthereumStakingAmountPage(
                                  mode: EthereumStakingAmountMode.deposit,
                                  authService: authService,
                                ),
                              ),
                            ),
                          ),
                          text: S.of(context).continue_text,
                          color: theme.colorScheme.primary,
                          textColor: theme.colorScheme.onPrimary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
