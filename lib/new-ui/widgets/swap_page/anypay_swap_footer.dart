import "package:auto_size_text/auto_size_text.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/bloc/swap_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/rates/rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/provider_selector_page.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class AnyPaySwapFooter extends StatelessWidget {
  const AnyPaySwapFooter({required this.bloc, super.key});

  final SwapBloc bloc;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return BlocBuilder<SwapBloc, SwapState>(
      bloc: bloc,
      builder: (context, state) => BlocBuilder<RateCubit, RateState>(
        bloc: bloc.rateCubit,
        builder: (context, rateState) {
          if (rateState is RatesNotFound) {
            return Container(
              alignment: Alignment.center,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.error),
              ),
              child: Text(
                S.of(context).no_providers_available,
                style: textTheme.bodyMedium?.copyWith(color: colors.error, letterSpacing: -0.07),
              ),
            );
          }

          if (state is! SwapInputState) {
            return const SizedBox.shrink();
          }

          ProviderRate? rate;
          if (rateState case final RatesLoaded rs) {
            rate = rs.rates.max;
          }

          final provider = rate?.provider;
          final depositAmount = state.depositAmount;
          final depositFiat = state.depositAmount.fiatAmount;
          return Row(
            children: [
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.primary),
                  ),
                  child: AutoSizeText.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: "${depositAmount.cryptoAmount.toStringWithSymbol()}"),
                        TextSpan(
                          text: "  ≈ ${depositFiat.toStringWithSymbol(fractionalDigits: 2)}",
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    minFontSize: 10,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.06,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (context) => Material(child: ProviderSelectorPage(bloc: bloc)),
                  ),
                ),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (provider != null)
                        CakeImageWidget(imageUrl: provider.image, width: 24, height: 24)
                      else
                        const CupertinoActivityIndicator(),
                      const SizedBox(width: 8),
                      Text(
                        provider?.title ?? "${S.of(context).finding_provider}...",
                        style: textTheme.bodyMedium?.copyWith(letterSpacing: -0.07),
                      ),
                      const SizedBox(width: 8),
                      CakeImageWidget(
                        imageUrl: "assets/new-ui/chooser.svg",
                        width: 12,
                        height: 12,
                        colorFilter: ColorFilter.mode(colors.onSurfaceVariant, BlendMode.srcIn),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
