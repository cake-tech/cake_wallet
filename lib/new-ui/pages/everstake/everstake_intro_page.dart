import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/everstake/everstake_amount_page.dart";
import "package:cake_wallet/new-ui/viewmodels/everstake/everstake_bloc.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_intro_view.dart";
import "package:cake_wallet/new-ui/widgets/everstake/everstake_rows.dart";
import "package:cake_wallet/new-ui/widgets/everstake/everstake_terms_text.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class EverstakeIntroPage extends StatelessWidget {
  const EverstakeIntroPage({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) => BlocBuilder<EverstakeBloc, EverstakeState>(
        builder: (context, state) {
          final data = state.data!;

          return DefiIntroView(
            wordmark: CakeImageWidget(
              imageUrl: "assets/new-ui/everstake_wordmark.svg",
              width: 234.922,
              height: 37.3,
              color: Theme.of(context).colorScheme.onSurface,
              semanticsLabel: "Everstake",
            ),
            description: data.apr == null
                ? S.of(context).everstake_intro
                : S.of(context).everstake_intro_apr(everstakeAprText(context, data.apr!)),
            details: [
              everstakeProviderRow(context),
              if (data.apr != null) everstakeYieldRow(context, data.apr!),
              if (data.activationTime != null)
                everstakeActivationRow(context, data.activationTime!),
              everstakeServiceFeeRow(context, data.poolFee),
            ],
            terms: EverstakeTermsText(S.of(context).everstake_terms_by_continuing),
            onContinue: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => Material(
                  color: Colors.transparent,
                  child: EverstakeAmountPage(
                    mode: EverstakeAmountMode.deposit,
                    authService: authService,
                  ),
                ),
              ),
            ),
          );
        },
      );
}
