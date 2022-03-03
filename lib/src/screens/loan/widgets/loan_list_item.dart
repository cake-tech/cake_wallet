import 'package:cake_wallet/src/screens/loan/widgets/loan_table.dart';
import 'package:cake_wallet/view_model/loan/loan_account_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class LoanListItem extends StatelessWidget {
  const LoanListItem({
    Key key,
    @required this.textColor,
    @required this.title,
    @required this.loginText,
    @required this.loanAccountViewModel,
    @required this.emptyListText,
  }) : super(key: key);

  final Color textColor;
  final String title;
  final String loginText;
  final String emptyListText;
  final LoanAccountViewModel loanAccountViewModel;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: Observer(builder: (_) {
        return ExpansionTile(
          initiallyExpanded: true,
          trailing: Icon(
            Icons.keyboard_arrow_down,
            color: textColor,
            size: 30,
          ),
          childrenPadding: EdgeInsets.symmetric(horizontal: 20),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor,
              fontSize: 24,
            ),
          ),
          children: [
            if (!loanAccountViewModel.isLoggedIn)
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  loginText,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              )
            else
              LoanTable(
                loanItems: loanAccountViewModel.items,
                emptyListText: emptyListText,
              ),
          ],
        );
      }),
    );
  }
}
