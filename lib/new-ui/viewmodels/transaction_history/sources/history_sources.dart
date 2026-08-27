import "package:cake_wallet/anonpay/anonpay_invoice_info.dart";
import "package:cake_wallet/new-ui/viewmodels/transaction_history/sources/store_sources.dart";
import "package:cake_wallet/order/order.dart";
import "package:cake_wallet/store/dashboard/order_filter_store.dart";
import "package:cake_wallet/store/dashboard/trade_filter_store.dart";
import "package:cake_wallet/store/dashboard/transaction_filter_store.dart";
import "package:cw_core/history_source.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";

typedef TransactionHistorySource
    = HistorySource<TransactionHistory<TransactionInfo>, TransactionFilterStore>;

typedef TradeHistorySource = HistorySource<TradeHistoryEmitter, TradeFilterStore>;

typedef OrderHistorySource = HistorySource<BoxHistoryEmitter<Order>, OrderFilterStore>;

typedef AnonpayHistorySource
    = HistorySource<BoxHistoryEmitter<AnonpayInvoiceInfo>, TransactionFilterStore>;

typedef PayjoinHistorySource = HistorySource<PayjoinHistoryEmitter, PayjoinFilterStore>;
