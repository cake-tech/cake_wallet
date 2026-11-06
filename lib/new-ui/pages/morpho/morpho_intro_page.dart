import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/core/morpho/morpho_vault.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/morpho/morpho_select_asset_page.dart";
import "package:cake_wallet/new-ui/pages/morpho/morpho_yield_by_asset_sheet.dart";
import "package:cake_wallet/new-ui/viewmodels/morpho/morpho_bloc.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_intro_view.dart";
import "package:cake_wallet/new-ui/widgets/morpho/morpho_badge.dart";
import "package:cake_wallet/new-ui/widgets/morpho/morpho_notice_text.dart";
import "package:cake_wallet/new-ui/widgets/morpho/morpho_rows.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class MorphoIntroPage extends StatelessWidget {
  const MorphoIntroPage({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) => BlocBuilder<MorphoBloc, MorphoState>(
        builder: (context, state) {
          final data = state.data!;

          return DefiIntroView(
            wordmark: CakeImageWidget(
              imageUrl: Theme.of(context).brightness == Brightness.dark
                  ? "assets/new-ui/morpho_wordmark_dark.svg"
                  : "assets/new-ui/morpho_wordmark_light.svg",
              height: 36,
              semanticsLabel: "Morpho",
            ),
            description: S.of(context).morpho_intro,
            details: [
              morphoProviderRow(context),
              morphoVariableYieldRow(
                context,
                subtitle: MorphoVault.usdcToken.title,
                onTap: () => MorphoYieldByAssetSheet.show(context: context, apy: data.apy),
              ),
            ],
            terms: const MorphoNoticeText(),
            attribution: const MorphoBadge(),
            onContinue: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => Material(
                  color: Colors.transparent,
                  child: MorphoSelectAssetPage(authService: authService),
                ),
              ),
            ),
          );
        },
      );
}
