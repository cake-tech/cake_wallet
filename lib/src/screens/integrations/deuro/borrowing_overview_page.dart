import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/loan_card_widget.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/view_model/integrations/deuro_borrowing_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/format_fixed.dart';
import 'package:flutter/material.dart';

class DEuroBorrowingOverviewPage extends BasePage {
  final DEuroBorrowingViewModel _dEuroViewModel;

  DEuroBorrowingOverviewPage(this._dEuroViewModel) {
    _dEuroViewModel.loadPosition();
  }

  @override
  String? get title => "dEuro Lending";

  @override
  Widget body(BuildContext context) {
    // WidgetsBinding.instance.addPostFrameCallback((_) => _setReactions(context, _dEuroViewModel));

    return RefreshIndicator(
      displacement: responsiveLayoutUtil.screenHeight * 0.1,
      onRefresh: _dEuroViewModel.loadPosition,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverFillRemaining(
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    ..._dEuroViewModel.positions.map(
                      (e) => LoanCardWidget(
                        loanAmount: formatFixed(BigInt.parse(e["principal"] as String), 18,
                            fractionalDigits: 2, trimZeros: false),
                        collateralAmount: formatFixed(
                            BigInt.parse(e["collateralBalance"] as String),
                            e["collateralDecimals"] as int),
                        collateralSymbol: e["collateralSymbol"] as String,
                        expiration: e["expiration"] as int,
                        currency: CryptoCurrency.deuro,
                        onManagePressed: () {},
                        onDetailsPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
