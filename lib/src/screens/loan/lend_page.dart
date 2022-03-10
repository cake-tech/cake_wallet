import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator_icon.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/view_model/loan/lend_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class LendPage extends BasePage {
  LendPage({@required this.lendViewModel}) : _formKey = GlobalKey<FormState>();

  final GlobalKey<FormState> _formKey;

  final LendViewModel lendViewModel;

  @override
  String get title => 'Lend';

  @override
  Color get titleColor => Colors.white;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  Color get textColor =>
      currentTheme.type == ThemeType.dark ? Colors.white : Color(0xff393939);

 @override
  Widget middle(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Observer(
              builder: (_) =>
                  SyncIndicatorIcon(isSynced: lendViewModel.status),
            ),
          ),
          Text(
            title,
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w600),
          ),
        ],
      );


  @override
  Widget trailing(context) => Observer(builder: (_) {
        return TrailButton(
            caption: S.of(context).clear,
            onPressed: () {
              _formKey.currentState.reset();
            });
      });

  @override
  Widget body(BuildContext context) {
    return Container(
      color: Theme.of(context).backgroundColor,
      child: Form(
        key: _formKey,
        child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(bottom: 24),
          content: Observer(
            builder: (_) => Container(
               width: double.infinity,
              padding: EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24)),
                gradient: LinearGradient(
                          colors: [
                            Theme.of(context)
                                .primaryTextTheme
                                .subtitle
                                .color,
                            Theme.of(context)
                                .primaryTextTheme
                                .subtitle
                                .decorationColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 100),
                   Text('Your deposit', style: TextStyle(color: Colors.white),)

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
