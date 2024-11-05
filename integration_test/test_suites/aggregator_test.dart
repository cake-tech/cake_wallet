import 'send_flow_test.dart' as send_flow_test;
import 'exchange_flow_test.dart' as exchange_flow_test;
import 'create_wallet_flow_test.dart' as create_wallet_flow_test;
import 'confirm_seeds_flow_test.dart' as confirm_seeds_flow_test;
import 'transaction_history_flow_test.dart' as transaction_history_flow_test;
import 'restore_wallet_through_seeds_flow_test.dart' as restore_wallet_through_seeds_flow_test;

Future<void> main() async {
  await send_flow_test.main();
  await exchange_flow_test.main();
  await restore_wallet_through_seeds_flow_test.main();
  await create_wallet_flow_test.main();
  await confirm_seeds_flow_test.main();
  await transaction_history_flow_test.main();
}
