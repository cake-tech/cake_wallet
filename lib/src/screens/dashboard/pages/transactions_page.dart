import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/csv_export_service.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/order/order_source_description.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/anonpay_transaction_row.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/order_row.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/payjoin_transaction_row.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/trade_row.dart';
import 'package:cake_wallet/src/widgets/dashboard_card_widget.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/order/order.dart';
import 'package:cake_wallet/view_model/dashboard/payjoin_transaction_list_item.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/header_row.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/date_section_raw.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/transaction_raw.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cake_wallet/view_model/dashboard/date_section_item.dart';
import 'package:intl/intl.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionsPage extends StatelessWidget {
  TransactionsPage({required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) => const Placeholder();
}
