import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/loan_card_widget.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/loan_details_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
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
  String? get title => "dEuro Borrowing";

  @override
  Widget body(BuildContext context) {
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
                        onDetailsPressed: () {
                          showModalBottomSheet<String?>(
                            context: context,
                            isScrollControlled: true,
                            builder: (BuildContext bottomSheetContext) => LoanDetailsSheet(
                              titleText: "Loan details",
                              loanAmount: formatFixed(BigInt.one, 18,
                                  fractionalDigits: 2, trimZeros: false),
                              retainedReserve: e['reserveContribution'].toString(),
                              liquidationPrice: formatFixed(
                                  BigInt.parse(e["virtualPrice"] as String), 18,
                                  fractionalDigits: 2, trimZeros: false),
                              expectedInterest: formatFixed(
                                  BigInt.parse(e["interest"] as String), 18,
                                  fractionalDigits: 2, trimZeros: false),
                              annualInterest: ((e["annualInterestPPM"] as int) / 10000).toString(),
                              originalPosition: e["original"] as String,
                              expiration:
                                  DateTime.now().add(Duration(days: 100)).millisecondsSinceEpoch,
                              currency: CryptoCurrency.deuro,
                              footerType: FooterType.none,
                              maxHeight: MediaQuery.of(context).size.height * 0.8,
                            ),
                          );
                        },
                        onManagePressed: () {},
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
