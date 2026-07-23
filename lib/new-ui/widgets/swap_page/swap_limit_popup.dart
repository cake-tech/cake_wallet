import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/rates/rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/swap_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_amount.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_amount_format.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_mobx/flutter_mobx.dart";

class SwapLimitPopup extends StatelessWidget {
  const SwapLimitPopup({super.key, required this.bloc});

  final SwapBloc bloc;

  static const outlineColor = Color(0xFFFFB84E);
  static const backgroundColor = Color(0xFF8E5800);

  @override
  Widget build(BuildContext context) => BlocBuilder<SwapBloc, SwapState>(
      bloc: bloc,
      builder: (context, state) => BlocBuilder<RateCubit, RateState>(
            builder: (context, rateState) {
              Money? max = null;
              Money? min = null;
              SwapAmount? amount = null;
              if (state case final SwapStateWithInputs s) {
                amount = s.depositAmount;
              }
              if (rateState case final RatesLoaded rs) {
                max = rs.maxLimit;
                min = rs.minLimit;
              }
              final tooLarge =
                  max != null && amount != null && !max.isZero && amount.cryptoAmount > max;
              final tooSmall =
                  min != null && amount != null && !min.isZero && amount.cryptoAmount < min;
              final show = tooLarge || tooSmall;
              return AnimatedSize(
                duration: Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                child: Container(
                  width: double.infinity,
                  child: Observer(builder: (_) {
                    final askText =
                        tooLarge ? S.of(context).enter_less_than : S.of(context).enter_greater_than;
                    final neededAmount = (tooLarge ? max : min).toString().withMaxDecimals(8);
                    final currency = amount?.currency.title ?? "";
                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: AnimatedOpacity(
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        opacity: show ? 1 : 0,
                        child: Container(
                          height: show ? null : 0,
                          decoration: BoxDecoration(
                              color: backgroundColor, borderRadius: BorderRadius.circular(99999)),
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              "$askText $neededAmount $currency",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: outlineColor, fontWeight: FontWeight.w500, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ));
}
