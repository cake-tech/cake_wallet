import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/order_details_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/list_row.dart';
import 'package:cake_wallet/src/screens/trade_details/track_trade_list_item.dart';

class OrderDetailsPage extends BasePage {
  OrderDetailsPage(this.orderDetailsViewModel);

  @override
  String get title => 'Order Details';

  final OrderDetailsViewModel orderDetailsViewModel;

  @override
  Widget body(BuildContext context) =>
      OrderDetailsPageBody(orderDetailsViewModel);
}

class OrderDetailsPageBody extends StatefulWidget {
  OrderDetailsPageBody(this.orderDetailsViewModel);

  final OrderDetailsViewModel orderDetailsViewModel;

  @override
  OrderDetailsPageBodyState createState() =>
      OrderDetailsPageBodyState(orderDetailsViewModel);
}

class OrderDetailsPageBodyState extends State<OrderDetailsPageBody> {
  OrderDetailsPageBodyState(this.orderDetailsViewModel);

  final OrderDetailsViewModel orderDetailsViewModel;

  @override
  void dispose() {
    super.dispose();
    orderDetailsViewModel.timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      return SectionStandardList(
          sectionCount: 1,
          itemCounter: (int _) => orderDetailsViewModel.items.length,
          itemBuilder: (__, index) {
            final item = orderDetailsViewModel.items[index];

            if (item is TrackTradeListItem) {
              return GestureDetector(
                  onTap: item.onTap,
                  child: ListRow(
                      title: '${item.title}', value: '${item.value}'));
            } else {
              return GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: '${item.value}'));
                    showBar<void>(context, S.of(context).copied_to_clipboard);
                  },
                  child: ListRow(
                      title: '${item.title}', value: '${item.value}'));
            }
          });
    });
  }

}