import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/seed_show_page_view_model.dart';
import 'package:flutter/material.dart';

class SeedShowPage extends BasePage {
  final SeedShowPageViewModel viewModel;
  
  SeedShowPage({required this.viewModel});

  @override
  Widget leading(BuildContext context) => SizedBox.shrink();

  @override
  String get title => S.current.seed_title;

  @override
  Widget body(BuildContext context) {
   return Container(
    padding: EdgeInsets.all(20),
    child: InkWell(
      onTap: () => viewModel.copySeed(context),
      child: Text(viewModel.seed)),
   );
  }
}